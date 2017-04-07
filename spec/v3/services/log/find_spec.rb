require 'spec_helper'

describe Travis::API::V3::Services::Log::Find, set_app: true do
  let(:user)        { Factory.create(:user) }
  let(:repo)        { Factory.create(:repository, owner_name: user.login, name: 'minimal', owner: user)}
  let(:build)       { Factory.create(:build, repository: repo) }
  let(:job)         { Travis::API::V3::Models::Job.create(build: build) }
  let(:job2)        { Travis::API::V3::Models::Job.create(build: build)}
  let(:job3)        { Travis::API::V3::Models::Job.create(build: build)}
  let(:s3job)       { Travis::API::V3::Models::Job.create(build: build) }
  let(:s3job2)       { Travis::API::V3::Models::Job.create(build: build) }
  let(:token)       { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers)     { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:parsed_body) { JSON.load(body) }
  let(:s3log)       { Travis::RemoteLog.new(job_id: s3job.id, content: 'minimal log 1') }
  let(:find_log)    { "string" }
  let(:time)        { Time.now }
  let(:xml_content) {
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <ListBucketResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">
    <Name>bucket</Name>
    <Prefix/>
    <Marker/>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
      <Contents>
          <Key>jobs/#{s3job.id}/log.txt</Key>
          <LastModified>2009-10-12T17:50:30.000Z</LastModified>
          <ETag>&quot;hgb9dede5f27731c9771645a39863328&quot;</ETag>
          <Size>20308738</Size>
          <StorageClass>STANDARD</StorageClass>
          <Owner>
              <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
              <DisplayName>mtd@amazon.com</DisplayName>
          </Owner>
          <body>$ git clean -fdx\nRemoving Gemfile.lock\n$ git fetch
          </body>
      </Contents>
    </ListBucketResult>"
  }

  let :log_from_api do
    {
      aggregated_at: Time.now,
      archive_verified: true,
      archived_at: Time.now,
      archiving: false,
      content: 'hello world. this is a really cool log',
      created_at: Time.now,
      id: 345,
      job_id: s3job.id,
      purged_at: Time.now,
      removed_at: Time.now,
      removed_by_id: 45,
      updated_at: Time.now
    }
  end

  let(:json_log_from_api) { log_from_api.to_json }

  before do
    Travis::API::V3::AccessControl::LegacyToken.any_instance.stubs(:visible?).returns(true)
    stub_request(:get, "https://bucket.s3.amazonaws.com/?max-keys=1000").
      to_return(:status => 200, :body => xml_content, :headers => {})
    stub_request(:get, "https://s3.amazonaws.com/archive.travis-ci.com/?prefix=jobs/#{s3job.id}/log.txt").
      to_return(status: 200, body: xml_content, headers: {})
    stub_request(:get, "https://s3.amazonaws.com/archive.travis-ci.com/?prefix=jobs/#{s3job2.id}/log.txt").
        to_return(status: 200, body: nil, headers: {})
    Fog.mock!
    storage = Fog::Storage.new({
      :aws_access_key_id => "key",
      :aws_secret_access_key => "secret",
      :provider => "AWS"
    })
    bucket = storage.directories.create(:key => 'archive.travis-ci.org')
    file = bucket.files.create(
      :key  => "jobs/#{s3job.id}/log.txt",
      :body => "$ git clean -fdx\nRemoving Gemfile.lock\n$ git fetch"
    )
    stub_request(:get, "http://travis-logs-notset.example.com:1234/logs/#{s3job.id}?by=job_id").
      with(headers: { 'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'token notset', 'User-Agent'=>'Faraday v0.9.2' }).
      to_return(status: 200, body: json_log_from_api, headers: {})
  end
  after { Fog::Mock.reset }

  around(:each) do |example|
    Travis.config.log_options.s3 = { access_key_id: 'key', secret_access_key: 'secret' }
    example.run
    Travis.config.log_options = {}
  end

  context 'when log not found in db but stored on S3' do
    describe 'returns log with an array of Log Parts' do
      example do
        s3log.attributes.merge!(archived_at: time, archive_verified: true)
        get("/v3/job/#{s3log.job.id}/log", {}, headers)

        expect(parsed_body).to eq(
          '@type' => 'log',
          '@href' => "/v3/job/#{s3job.id}/log",
          '@representation' => 'standard',
          '@permissions' => {
            'read' => true,
            'debug' => false,
            'cancel' => false,
            'restart' => false,
            'delete_log' => false
          },
          'id' => log_from_api[:id],
          'content' => log_from_api[:content],
          'log_parts' => [
            {
              'content' => 'hello world. this is a really cool log',
              'final' => true,
              'number' => 0
            }
          ]
        )
      end
    end

    describe 'returns log as plain text' do
      example do
        s3log.attributes.merge!(archived_at: Time.now, archive_verified: true)
        get("/v3/job/#{s3log.job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
        expect(last_response.headers).to include('Content-Type' => 'text/plain')
        expect(body).to eq(log_from_api[:content])
      end
    end

    describe 'it returns the correct content type' do
      example do
        s3log.attributes.merge!(archived_at: Time.now, archive_verified: true)
        get("/v3/job/#{s3log.job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'fun/times'))
        expect(last_response.headers).to include('Content-Type' => 'application/json')
      end
    end
  end
end
