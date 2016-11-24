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
  # let(:log3)        { Travis::API::V3::Models::Log.create(job: job3) }
  let(:s3log)       { Travis::API::V3::Models::Log.create(job: s3job, content: 'minimal log 1') }

  before do
    Travis::API::V3::AccessControl::LegacyToken.any_instance.stubs(:visible?).returns(true)
    Travis::API::V3::Permissions::Job.any_instance.stubs(:delete_log?).returns(true)
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
    # before { log3.delete }

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
    before { job.update_attributes(finished_at: Time.now)}
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
      Travis::API::V3::Queries::Log::S3.any_instance.expects(:delete_log)
    end

    describe 'updates log, inserts new log part' do
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
