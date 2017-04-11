require 'spec_helper'

describe Travis::API::V3::Services::Log::Delete, set_app: true do
  let(:user)        { Factory.create(:user) }
  let(:repo)        { Factory.create(:repository, owner_name: user.login, name: 'minimal', owner: user)}
  let(:repo2)       { Factory.create(:repository, owner_name: user.login, name: 'minimal2', owner: user)}
  let(:build)       { Factory.create(:build, repository: repo) }
  let(:build2)      { Factory.create(:build, repository: repo2) }
  let(:job)         { Travis::API::V3::Models::Job.create(build: build) }
  let(:job2)        { Travis::API::V3::Models::Job.create(build: build2) }
  let(:job3)        { Travis::API::V3::Models::Job.create(build: build2) }
  let(:s3job)       { Travis::API::V3::Models::Job.create(build: build) }
  let(:token)       { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers)     { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:parsed_body) { JSON.load(body) }
  let(:log)         { Travis::API::V3::Models::Log.create(job: job) }
  let(:log2)        { Travis::API::V3::Models::Log.create(job: job2) }
  let(:s3log)       { Travis::API::V3::Models::Log.create(job: s3job, content: 'minimal log 1') }
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

  around(:each) do |example|
    Travis.config.log_options.s3 = { access_key_id: 'key', secret_access_key: 'secret' }
    example.run
    Travis.config.log_options = {}
  end

  before do
    Travis::API::V3::AccessControl::LegacyToken.any_instance.stubs(:visible?).returns(true)
    Travis::API::V3::Permissions::Job.any_instance.stubs(:delete_log?).returns(true)
    stub_request(:get, "https://bucket.s3.amazonaws.com/?max-keys=1000").
      to_return(:status => 200, :body => xml_content, :headers => {})
    stub_request(:get, "https://s3.amazonaws.com/archive.travis-ci.org/?prefix=jobs/#{job.id}/log.txt").
      to_return(:status => 200, :body => xml_content, :headers => {})
  end

  describe "not authenticated" do
    before  { delete("/v3/job/#{job.id}/log")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  describe "missing log, authenticated" do
    before { job3.update_attributes(finished_at: Time.now, state: "passed")}

    example do
      stub_request(
        :get,
        "#{Travis.config.logs_api.url}/logs/#{job3.id}?by=job_id&source=api"
      ).to_return(status: 404)
      delete("/v3/job/#{job3.id}/log", {}, headers)
      expect(last_response.status).to be == 404
      expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "not_found",
        "error_message" => "log not found"
      }
    end
  end
end
