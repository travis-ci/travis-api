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

  before { Travis::API::V3::AccessControl::LegacyToken.any_instance.stubs(:visible?).returns(true) }

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

    describe 'returns log as plain text' do
      example do
        log_part = log.log_parts.create(content: "logging it", number: 1)
        log_part2 = log.log_parts.create(content: "logging more", number: 2)
        log_part3 = log.log_parts.create(content: "logging forever", number: 3)


        get("/v3/job/#{log.job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
        expect(body).to eq(
          "logging it\nlogging more\nlogging forever\n")
      end
    end
  end

  context 'when log not found in db but stored on S3' do
    describe 'returns log with an array of Log Parts' do
      before do
        stub_request(:get, "https://s3.amazonaws.com/archive.travis-ci.org/jobs/#{s3job.id}/log.txt").
         with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'s3.amazonaws.com', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "$ git clean -fdx\nRemoving Gemfile.lock\n$ git fetch", :headers => {})
      end
      example do
        s3log.update_attributes(archived_at: Time.now)
        get("/v3/job/#{s3job.id}/log", {}, headers)

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
        stub_request(:get, "https://s3.amazonaws.com/archive.travis-ci.org/jobs/#{s3job.id}/log.txt").
         with(:headers => {'Accept'=>'text', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'s3.amazonaws.com', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "$ git clean -fdx\nRemoving Gemfile.lock\n$ git fetch", :headers => {})
      end
      example do
        get("/v3/job/#{s3log.job.id}/log", {}, headers.merge('HTTP_ACCEPT' => 'text/plain'))
        expect(body).to eq(
          '@href' => "/v3/job/#{s3log.job.id}/log/loggy")
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
