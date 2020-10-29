require 'travis/api/v3/log_token'

describe Travis::API::V3::Services::Job::Find, set_app: true do
  include Support::Formats
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:secure) { Travis::SecureConfig.new(repo.key) }
  let(:owner_href)  { repo.owner_type.downcase }
  let(:owner_type)  { repo.owner_type.constantize }
  let(:owner)       { owner_type.find(repo.owner_id)}
  let(:build)       { repo.builds.last }
  let(:job)         { Travis::API::V3::Models::Build.find(build.id).jobs.last }
  let(:job2)        { Travis::API::V3::Models::Build.find(build.id).jobs.first }
  let(:stage)       { Travis::API::V3::Models::Stage.create!(number: 1, name: 'test') }
  let(:commit)      { job.commit }
  let(:config)      { {:language=>"shell",
                       :addons=>{ :mariadb=>'10.0', :sauce_connect => true },
                       :global_env => [secure.encrypt('FOO=bar')],
                       :env=> [secure.encrypt('SUPER=duper')],
                       :notifications => {
                         :slack => {
                           rooms: [{ secure: 'foo'}]
                         }
                       }
                     }
                   }
  let(:parsed_body) { JSON.load(body) }

  before do
    # TODO should this go into the scenario? is it ok to keep it here?
    job.update_attributes!(stage: stage)
    job2.update_attributes!(config: config, stage: stage)
    # for some reason update_attributes! doesn't update updated_at
    # and it doesn't play well with out triggers (as triggers will update
    # updated_at and instance variable in tests will have a different value)
    job.reload
    job2.reload
  end

  describe "fetching job on a public repository, no pull access" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: false) }
    before     { get("/v3/job/#{job.id}")     }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to eql_json({
      "@type"                 => "job",
      "@href"                 => "/v3/job/#{job.id}",
      "@representation"       => "standard",
      "@permissions"          => {
        "read"                => true,
        "cancel"              => false,
        "restart"             => false,
        "debug"               => false,
        "delete_log"          => false,
        "prioritize"          => false },
      "id"                    => job.id,
      "allow_failure"         => job.allow_failure,
      "number"                => job.number,
      "state"                 => job.state,
      "started_at"            => "2010-11-12T12:00:00Z",
      "finished_at"           => "2010-11-12T12:00:10Z",
      "created_at"            => json_format_time_with_ms(job.created_at),
      "updated_at"            => json_format_time_with_ms(job.updated_at),
      "private"               => false,
      "build"                 => {
        "@type"               => "build",
        "@href"               => "/v3/build/#{build.id}",
        "@representation"     => "minimal",
        "id"                  => build.id,
        "number"              => build.number,
        "state"               => build.state,
        "duration"            => build.duration,
        "event_type"          => build.event_type,
        "previous_state"      => build.previous_state,
        "pull_request_number" => build.pull_request_number,
        "pull_request_title"  => build.pull_request_title,
        "private"             => false,
        "priority"            => false,
        "started_at"          => "2010-11-12T12:00:00Z",
        "finished_at"         => "2010-11-12T12:00:10Z"},
      "stage"                 => {
        "@type"               => "stage",
        "@representation"     => "minimal",
        "id"                  => stage.id,
        "number"              => 1,
        "name"                => "test",
        "state"               => stage.state,
        "started_at"          => stage.started_at,
        "finished_at"         => stage.finished_at},
      "queue"                 => job.queue,
      "repository"            => {
        "@type"               => "repository",
        "@href"               => "/v3/repo/#{repo.id}",
        "@representation"     => "minimal",
        "id"                  => repo.id,
        "name"                => repo.name,
        "slug"                => repo.slug},
      "commit"                => {
        "@type"               => "commit",
        "@representation"     => "minimal",
        "id"                  => commit.id,
        "sha"                 => commit.commit,
        "ref"                 => commit.ref,
        "message"             => commit.message,
        "compare_url"         => commit.compare_url,
        "committed_at"        => "2010-11-12T11:50:00Z"},
      "owner"                 => {
        "@type"               => owner_type.to_s.downcase,
        "@href"               => "/v3/#{owner_href}/#{owner.id}",
        "@representation"     => "minimal",
        "id"                  => owner.id,
        "login"               => owner.login,
        "name"                => owner.name,
        "vcs_type"            => owner.vcs_type
      }
    })}
  end

  describe "fetching a non-existing job" do
    before     { get("/v3/job/1233456789")     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to eql_json({
      "@type"         =>  "error",
      "error_type"    =>  "not_found",
      "error_message" =>  "job not found (or insufficient access)",
      "resource_type" =>  "job"
    })}
  end

  describe "fetching job on private job on public repository, not authenticated" do
    before  { job.update_attribute(:private, true)  }
    before  { get("/v3/job/#{job.id}", {}, {})      }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to eql_json({
      "@type"         =>  "error",
      "error_type"    =>  "not_found",
      "error_message" =>  "job not found (or insufficient access)",
      "resource_type" =>  "job"
    })}
  end

  describe "fetching job on private repository, private API, with a log.token" do
    let(:log_token) { Travis::API::V3::LogToken.create(job).to_s }
    before        { repo.update_attribute(:private, true)                   }
    before        { get("/v3/job/#{job.id}?log.token=#{log_token}", {}, {}) }
    after         { repo.update_attribute(:private, false)                  }
    example       { expect(last_response).to_not be_ok                      }
    example       { expect(last_response.status).to eq 404                  }
  end

  describe "fetching job on private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { allow_any_instance_of(Travis::API::V3::Permissions::Job).to receive(:delete_log?).and_return(true) }
    before        { allow_any_instance_of(Travis::API::V3::Permissions::Job).to receive(:prioritize?).and_return(true) }
    before        { get("/v3/job/#{job.id}", {}, headers)                             }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to eql_json({
      "@type"                 => "job",
      "@href"                 => "/v3/job/#{job.id}",
      "@representation"       => "standard",
      "@permissions"          => {
        "read"                => true,
        "cancel"              => true,
        "restart"             => true,
        "debug"               => false,
        "delete_log"          => true,
        "prioritize"          => true },
      "id"                    => job.id,
      "allow_failure"         => job.allow_failure,
      "number"                => job.number,
      "state"                 => job.state,
      "started_at"            => "2010-11-12T12:00:00Z",
      "finished_at"           => "2010-11-12T12:00:10Z",
      "created_at"            => json_format_time_with_ms(job.created_at),
      "updated_at"            => json_format_time_with_ms(job.updated_at),
      "private"               => false,
      "build"                 => {
        "@type"               => "build",
        "@href"               => "/v3/build/#{build.id}",
        "@representation"     => "minimal",
        "id"                  => build.id,
        "number"              => build.number,
        "state"               => build.state,
        "duration"            => build.duration,
        "event_type"          => build.event_type,
        "previous_state"      => build.previous_state,
        "pull_request_number" => build.pull_request_number,
        "pull_request_title"  => build.pull_request_title,
        "private"             => false,
        "priority"            => false,
        "started_at"          => "2010-11-12T12:00:00Z",
        "finished_at"         => "2010-11-12T12:00:10Z"},
      "stage"                 => {
        "@type"               => "stage",
        "@representation"     => "minimal",
        "id"                  => stage.id,
        "number"              => 1,
        "name"                => "test",
        "state"               => stage.state,
        "started_at"          => stage.started_at,
        "finished_at"         => stage.finished_at},
      "queue"                 => job.queue,
      "repository"            => {
        "@type"               => "repository",
        "@href"               => "/v3/repo/#{repo.id}",
        "@representation"     => "minimal",
        "id"                  => repo.id,
        "name"                => repo.name,
        "slug"                => repo.slug},
      "commit"                => {
        "@type"               => "commit",
        "@representation"     => "minimal",
        "id"                  => commit.id,
        "sha"                 => commit.commit,
        "ref"                 => commit.ref,
        "message"             => commit.message,
        "compare_url"         => commit.compare_url,
        "committed_at"        => "2010-11-12T11:50:00Z"},
      "owner"                 => {
        "@type"               => owner_type.to_s.downcase,
        "@href"               => "/v3/#{owner_href}/#{owner.id}",
        "@representation"     => "minimal",
        "id"                  => owner.id,
        "login"               => owner.login,
        "name"                => owner.name,
        "vcs_type"            => owner.vcs_type
      }
    })}
  end

  describe "config is correctly obfuscated" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: false) }
    before     { get("/v3/job/#{job2.id}?include=job.config")     }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to eql_json({
      "@type"                 => "job",
      "@href"                 => "/v3/job/#{job2.id}",
      "@representation"       => "standard",
      "@permissions"          => {
        "read"                => true,
        "cancel"              => false,
        "restart"             => false,
        "debug"               => false,
        "delete_log"          => false,
        "prioritize"          => false },
      "id"                    => job2.id,
      "allow_failure"         => job2.allow_failure,
      "number"                => job2.number,
      "state"                 => job2.state,
      "started_at"            => "2010-11-12T12:00:00Z",
      "finished_at"           => "2010-11-12T12:00:10Z",
      "created_at"            => json_format_time_with_ms(job2.created_at),
      "updated_at"            => json_format_time_with_ms(job2.updated_at),
      "private"               => false,
      "build"                 => {
        "@type"               => "build",
        "@href"               => "/v3/build/#{build.id}",
        "@representation"     => "minimal",
        "id"                  => build.id,
        "number"              => build.number,
        "state"               => build.state,
        "duration"            => build.duration,
        "event_type"          => build.event_type,
        "previous_state"      => build.previous_state,
        "pull_request_number" => build.pull_request_number,
        "pull_request_title"  => build.pull_request_title,
        "private"             => false,
        "priority"            => false,
        "started_at"          => "2010-11-12T12:00:00Z",
        "finished_at"         => "2010-11-12T12:00:10Z"},
      "stage"                 => {
        "@type"               => "stage",
        "@representation"     => "minimal",
        "id"                  => stage.id,
        "number"              => 1,
        "name"                => "test",
        "state"               => stage.state,
        "started_at"          => stage.started_at,
        "finished_at"         => stage.finished_at},
      "queue"                 => job2.queue,
      "repository"            => {
        "@type"               => "repository",
        "@href"               => "/v3/repo/#{repo.id}",
        "@representation"     => "minimal",
        "id"                  => repo.id,
        "name"                => repo.name,
        "slug"                => repo.slug},
      "commit"                => {
        "@type"               => "commit",
        "@representation"     => "minimal",
        "id"                  => commit.id,
        "sha"                 => commit.commit,
        "ref"                 => commit.ref,
        "message"             => commit.message,
        "compare_url"         => commit.compare_url,
        "committed_at"        => "2010-11-12T11:50:00Z"},
      "owner"                 => {
        "@type"               => owner_type.to_s.downcase,
        "@href"               => "/v3/#{owner_href}/#{owner.id}",
        "@representation"     => "minimal",
        "id"                  => owner.id,
        "login"               => owner.login,
        "name"                => owner.name,
        "vcs_type"            => owner.vcs_type
      },
      "config"                => {
        "language" => "shell",
        "addons" => { "mariadb" => "10.0" },
        "global_env" => "FOO=[secure]",
        "env" => "SUPER=[secure]",
        "notifications" => { "slack" => {
          "rooms" => [
            {"secure"=>"foo"}
          ]
        }}}
    })}
  end

  describe 'including log_complete on hosted' do
    before do
      stub_request(:get, "http://travis-logs-notset.example.com:1234/logs/#{job.id}?by=job_id&source=api").
         with(  headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization'=>'token notset',
          'Connection'=>'keep-alive',
          'Keep-Alive'=>'30',
          'User-Agent'=>'Faraday v0.17.3'
           }).
         to_return(status: 200, body: "{}", headers: {})
    end

    before { get("/v3/job/#{job.id}?include=job.log_complete") }

    example { expect(last_response).to be_ok }
    example do
      expect(parsed_body).to include('log_complete')
    end
  end

  describe 'including log_complete on enterprise' do
    before do
      stub_request(:get, "http://travis-logs-notset.example.com:1234/logs/#{job2.id}?by=job_id&source=api").
         with(  headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization'=>'token notset',
          'Connection'=>'keep-alive',
          'Keep-Alive'=>'30',
          'User-Agent'=>'Faraday v0.17.3'
           }).
         to_return(status: 200, body: "{}", headers: {})

    end
    before { Travis.config.enterprise = true }
    after { Travis.config.enterprise = false }

    before { get("/v3/job/#{job2.id}?include=job.log_complete") }

    example { expect(last_response).to be_ok }
    example do
      expect(parsed_body).to include('log_complete')
    end
  end
end
