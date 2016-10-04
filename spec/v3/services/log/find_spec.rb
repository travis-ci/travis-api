require 'spec_helper'

describe Travis::API::V3::Services::Log::Find, set_app: true do
  let(:user)        { Factory.create(:user) }
  let(:repo)        { Factory.create(:repository, owner_name: user.login, name: 'minimal', owner: user)}
  let(:build)       { Factory.create(:build, repository: repo) }
  let(:job)         { Travis::API::V3::Models::Job.create(build: build) }
  let(:job2)        { Travis::API::V3::Models::Job.create(build: build)}
  let(:s3job)       { Travis::API::V3::Models::Job.create(build: build) }
  let(:token)       { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers)     { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  let(:parsed_body) { JSON.load(body) }
  let(:log)         { Travis::API::V3::Models::Log.create(job: job) }
  let(:log2)        { Travis::API::V3::Models::Log.create(job: job2) }
  let(:s3log)       { Travis::API::V3::Models::Log.create(job: s3job, content: 'minimal log 1') }
  let(:find_log)    { "string" }
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


  before do
    Travis::API::V3::AccessControl::LegacyToken.any_instance.stubs(:visible?).returns(true)
    stub_request(:get, "https://bucket.s3.amazonaws.com/?max-keys=1000").
      to_return(:status => 200, :body => xml_content, :headers => {})
    stub_request(:get, "https://s3.amazonaws.com/archive.travis-ci.org/?prefix=jobs/#{s3job.id}/log.txt").
      to_return(status: 200, body: xml_content, headers: {})
  end

  context 'when log stored in db' do
    describe 'returns log with an array of Log Parts' do
      example do
        log_part = log.log_parts.create(content: "logging it", number: 0)
        get("/v3/job/#{log.job.id}/log", {}, headers)
        expect(parsed_body).to eq(
          '@href' => "/v3/job/#{log.job.id}/log",
          '@representation' => 'standard',
          '@type' => 'log',
          'content' => nil,
          'id' => log.id,
          'log_parts'       => [{
          "@type"           => "log_part",
          "@representation" => "minimal",
          "content"         => log_part.content,
          "number"          => log_part.number }])
      end
    end

    describe 'returns aggregated log with an array of Log Parts' do
      before { log2.update_attributes(aggregated_at: Time.now, content: "aggregating!")}
      example do
        # log_part = log2.log_parts.create(content: "logging it", number: 0)
        get("/v3/job/#{log2.job.id}/log", {}, headers)
        expect(parsed_body).to eq(
          '@type' => 'log',
          '@href' => "/v3/job/#{log2.job.id}/log",
          '@representation' => 'standard',
          'content' => "aggregating!",
          'id' => log2.id,
          'log_parts'       => [{
          "@type"           => "log_part",
          "@representation" => "minimal",
          "content"         => "aggregating!",
          "number"          => 0 }])
      end
    end

    describe 'returns log as plain text' do
      example do
        log_part = log.log_parts.create(content: "logging it", number: 1)
        log_part2 = log.log_parts.create(content: "logging more", number: 2)
        log_part3 = log.log_parts.create(content: "logging forever", number: 3)

        get("/v3/job/#{log.job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
        expect(body).to eq(
          "logging it\nlogging more\nlogging forever")
      end
    end
  end

  context 'when log not found in db but stored on S3' do
    describe 'returns log with an array of Log Parts' do
      before do
        stub_request(:get, "https://bucket.s3.amazonaws.com/?max-keys=1000").
          to_return(:status => 200, :body => xml_content, :headers => {})
        stub_request(:get, "https://s3.amazonaws.com/archive.travis-ci.org/jobs/#{s3job.id}/log.txt").
         to_return(status: 200, body: xml_content, headers: {})
      end
      example do
        s3log.update_attributes(archived_at: Time.now)
        get("/v3/job/#{s3log.job.id}/log", {}, headers)

        expect(parsed_body).to eq(
          '@type' => 'log',
          '@href' => "/v3/job/#{s3job.id}/log",
          '@representation' => 'standard',
          'id' => s3log.id,
          'content' => 'minimal log 1',
          'log_parts'       => [{
            "@type"=>"log_part",
            "@representation"=>"minimal",
            "content"=>"$ git clean -fdx\nRemoving Gemfile.lock\n$ git fetch",
            "number"=>0}])
      end
    end
    describe 'returns log as plain text' do
      before do
        Fog.mock!
        storage = Fog::Storage.new({
          :aws_access_key_id => "asdf",
          :aws_secret_access_key => "asdf",
          :provider => "AWS"
        })
        storage.data[:foo] = '25'
        Fog::Storage.any_instance.stub(:fetch).and_return(storage.data)
        # stub_request(:get, "https://s3.amazonaws.com/archive.travis-ci.org/jobs/#{s3job.id}/log.txt").
        #  to_return(status: 200, body: xml_content, headers: {})
      end
      after do
        Fog::Mock.reset
      end

      example do
        s3log.update_attributes(archived_at: Time.now)
        get("/v3/job/#{s3log.job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
        expect(last_response.headers).to include("Content-Type" => "text/plain")
        expect(body).to eq(
          "$ git clean -fdx\nRemoving Gemfile.lock\n$ git fetch")
      end
    end
  end

  context 'when log not found anywhere' do
    describe 'does not return log - returns error' do
      before { log.delete }
      example do
        get("/v3/job/#{job.id}/log", {}, headers)
        expect(parsed_body).to eq({
          "@type"=>"error",
          "error_type"=>"not_found",
          "error_message"=>"log not found"})
        end
    end
  end

  context 'when log removed by user' do
    describe 'does not return log'
  end
end
