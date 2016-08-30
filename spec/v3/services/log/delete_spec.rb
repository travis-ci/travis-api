require 'spec_helper'

describe Travis::API::V3::Services::Log::Delete, set_app: true do
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
    before        { log.delete }
    before        { delete("/v3/job/#{log.job.id}/log", {}, headers)                 }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "log not found"
    }}
  end

  describe 'existing db log, authenticated' do
    before { job.update_attributes(finished_at: Time.now)}
    example do
      delete("/v3/job/#{log.job.id}/log", {}, headers)
      expect(last_response.status).to be == 409
      expect(parsed_body).to eq({
        '@type' => 'error',
        'error_message' => "job for this log is not finished, please wait until job has finished before retrieving log",
        'error_type' => 'job_unfinished'
        })
    end
  end

  context 's3 log, authenticated' do
    describe 'updates log, inserts new log part' do
      example do
        s3log.update_attributes(archived_at: Time.now)
        delete("/v3/job/#{s3job.id}/log", {}, headers)
        expect(last_response.status).to be == 409

        expect(parsed_body).to eq({
          '@href' => "/v3/job/#{s3job.id}/log",
          '@representation' => 'standard',
          '@type' => 'log',
          'content' => 'minimal log 1'})
      end
    end
  end
  #
  # context 'when log not found anywhere' do
  #   describe 'does not return log - returns error' do
  #     before { log.delete }
  #     example do
  #       delete("/v3/job/#{job.id}/log", {}, headers)
  #       expect(parsed_body).to eq({
  #         "@type"=>"error",
  #         "error_type"=>"not_found",
  #         "error_message"=>"log not found"})
  #       end
  #   end
  # end
  #
  # context 'when job for log is still running' do
  #   describe 'does not return log - returns JobUnfinished error' do
  #     before { job2.update_attributes(finished_at: nil)}
  #     example do
  #       delete("/v3/job/#{job2.id}/log", {}, headers)
  #       expect(parsed_body).to eq({
  #         "@type"=>"error",
  #         "error_type"=>"job_unfinished",
  #         "error_message"=>"job for this log is not finished, please wait until job has finished before retrieving log"})
  #     end
  #   end
  # end
end
