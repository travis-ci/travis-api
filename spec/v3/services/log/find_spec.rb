require 'spec_helper'

describe Travis::API::V3::Services::Log::Find, set_app: true do
  let(:user)        { Travis::API::V3::Models::User.find_by_login('svenfuchs') }
  let(:repo)        { Travis::API::V3::Models::Repository.where(owner_name: user.login, name: 'minimal').first }
  let(:build)       { repo.builds.last }
  let(:job)         { Travis::API::V3::Models::Build.find(build.id).jobs.last }
  let(:s3job)       { Travis::API::V3::Models::Build.find(build.id).jobs.first }
  let(:token)       { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers)     { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:parsed_body) { JSON.load(body) }
  let(:log)         { job.log }
  let(:s3log)       { s3job.log }
  # before { s3log.update_attribute(:archived_at, Time.now) }


  context 'when log stored in db' do
    describe 'returns log with an array of Log Parts' do
      example do
        log_part = log.log_parts.create(content: "logging it", number: 0)
        get("/v3/job/#{job.id}/log", {}, headers)
        expect(parsed_body).to eq(
          '@href' => "/v3/job/#{job.id}/log",
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
    describe 'returns log as plain text'
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
          '@href' => "/v3/job/#{s3job.id}/log",
          '@representation' => 'standard',
          '@type' => 'log',
          'content' => 'minimal log 1',
          'id' => s3log.id,
          'log_parts'       => [{
            "@type"=>"log_part",
            "@representation"=>"minimal",
            "content"=>"$ git clean -fdx",
            "number"=>0}, {
            "@type"=>"log_part",
            "@representation"=>"minimal",
            "content"=>"Removing Gemfile.lock",
            "number"=>1}, {
            "@type"=>"log_part",
            "@representation"=>"minimal",
            "content"=>"$ git fetch",
            "number"=>2}])
      end
    end
    describe 'returns log as plain text'
  end

  context 'when log not found anywhere' do
    describe 'does not return log'
  end

  context 'when log removed by user' do
    describe 'does not return log'
  end
end
