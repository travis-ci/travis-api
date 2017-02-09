require 'spec_helper'

describe Travis::API::V3::Services::Log::Delete, set_app: true do
  let(:user)        { Factory.create(:user) }
  let(:repo)        { Factory.create(:repository, owner_name: user.login, name: 'minimal', owner: user, github_id: 98 )}
  let(:repo2)       { Factory.create(:repository, owner_name: user.login, name: 'minimal2', owner: user, github_id: 99 )}
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

  before do
    Travis::API::V3::AccessControl::LegacyToken.any_instance.stubs(:visible?).returns(true)
    Travis::API::V3::Permissions::Job.any_instance.stubs(:delete_log?).returns(true)
    stub_request(:get, "https://bucket.s3.amazonaws.com/?max-keys=1000").
      to_return(:status => 200, :body => xml_content, :headers => {})
    stub_request(:get, "https://s3.amazonaws.com/archive.travis-ci.org/?prefix=jobs/#{log.job.id}/log.txt").
      to_return(:status => 200, :body => xml_content, :headers => {})
  end

  describe "not authenticated" do
    before  { delete("/v3/job/#{log.job.id}/log")      }
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
      delete("/v3/job/#{job3.id}/log", {}, headers)
      expect(last_response.status).to be == 404
      expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "not_found",
        "error_message" => "log not found"
      }
    end
  end

  describe 'existing db log, authenticated' do
    before do
      Timecop.return
      Timecop.freeze(Time.now.utc)
      job.update_attributes(finished_at: Time.now)
    end
    after { Timecop.return }
    example do
      delete("/v3/job/#{log.job.id}/log", {}, headers)
      expect(last_response.status).to be == 200
      expect(JSON.load(body)).to be == {"@type"=>"log",
        "@href"=>"/v3/job/#{log.job.id}/log",
        "@representation"=>"standard",
        "id"=>log.id,
        "content"=>nil,
        "log_parts"=>[{
          "@type"=>"log_part",
          "@representation"=>"minimal",
          "content"=>"Log removed by Sven Fuchs at #{Time.now.utc}",
          "number"=>1}]}
    end
  end

  context 's3 log, authenticated' do
    before do
      s3job.update_attributes(finished_at: Time.now)
      Fog.mock!
      Travis.config.logs_options.s3 = { access_key_id: 'key', secret_access_key: 'secret' }
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
    end
    after { Fog::Mock.reset }

    describe 'updates log, inserts new log part' do
      before do
        Timecop.return
        Timecop.freeze(Time.now.utc)
      end
      after { Timecop.return }
      example do
        s3log.update_attributes(archived_at: Time.now)
        delete("/v3/job/#{s3log.job.id}/log", {}, headers)
        expect(last_response.status).to be == 200
        expect(JSON.load(body)).to be == {"@type"=>"log",
          "@href"=>"/v3/job/#{s3log.job.id}/log",
          "@representation"=>"standard",
          "id"=>s3log.id,
          "content"=>nil,
          "log_parts"=>[{
            "@type"=>"log_part",
            "@representation"=>"minimal",
            "content"=>"Log removed by Sven Fuchs at #{Time.now.utc}",
            "number"=>1}]}
      end
    end
  end

  context 'when job for log is still running, authenticated' do
    example do
      delete("/v3/job/#{log2.job.id}/log", {}, headers)
      expect(last_response.status).to be == 409
      expect(parsed_body).to eq({
        "@type"=>"error",
        "error_type"=>"job_unfinished",
        "error_message"=>"job still running, cannot remove log yet"})
    end
  end

  context 'when log already removed_at, authenticated' do
    before { log2.update_attributes(removed_at: Time.now) }
    example do
      delete("/v3/job/#{log2.job.id}/log", {}, headers)
      expect(last_response.status).to be == 409
      expect(parsed_body).to eq({
        "@type"=>"error",
        "error_type"=>"log_already_removed",
        "error_message"=>"log has already been removed"})
    end
  end

  context 'when log already removed_by, authenticated' do
    before { log2.update_attributes(removed_by: user) }
    example do
      delete("/v3/job/#{log2.job.id}/log", {}, headers)
      expect(last_response.status).to be == 409
      expect(parsed_body).to eq({
        "@type"=>"error",
        "error_type"=>"log_already_removed",
        "error_message"=>"log has already been removed"})
    end
  end
end
