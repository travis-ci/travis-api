require 'spec_helper'

describe Travis::API::V3::Services::Builds::Find do
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }
  let(:build) { repo.builds.last }
  let(:parsed_body) { JSON.load(body) }

  describe "fetching builds on a public repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal/builds")     }
    example    { expect(last_response).to be_ok }
  end

  describe "fetching builds on a non-existing repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal1/builds")     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "builds on public repository" do
    before     { get("/v3/repo/#{repo.id}/builds?limit=1") }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type"              => "builds",
      "@href"              => "/v3/repo/#{repo.id}/builds?limit=1",
      "@pagination"        => {
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 3,
        "is_first"         => true,
        "is_last"          => false,
        "next"             => {
          "@href"          => "/v3/repo/1/builds?limit=1&offset=1",
          "offset"         => 1,
          "limit"          =>1},
        "prev"             =>nil,
        "first"            => {
          "@href"          => "/v3/repo/1/builds?limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/1/builds?limit=1&offset=2",
          "offset"         => 2,
          "limit"          => 1 }},
      "builds"             => [{
        "@type"            => "build",
        "@href"            => "/v3/build/#{build.id}",
        "id"               => build.id,
        "number"           => "3",
        "state"            => "configured",
        "duration"         => nil,
        "event_type"       => "push",
        "previous_state"   => "passed",
        "started_at"       => "2010-11-12T13:00:00Z",
        "finished_at"      => nil,
        "repository"       => {
          "@type"          => "repository",
          "@href"          => "/v3/repo/1",
          "id"             => 1,
          "slug"=>"svenfuchs/minimal" },
        "branch"           => {
          "@type"          => "branch",
          "@href"          => "/v3/repo/1/branch/master",
          "name"           => "master",
          "last_build"     => {
            "@href"=>"/v3/build/#{build.id}" }},
        "commit"           => {
          "@type"          => "commit",
          "id"             => 5,
          "sha"            => "add057e66c3e1d59ef1f",
          "ref"            => "refs/heads/master",
          "message"        => "unignore Gemfile.lock",
          "compare_url"    => "https://github.com/svenfuchs/minimal/compare/master...develop",
          "committed_at"   => "2010-11-12T12:55:00Z"}}],
   }}
  end

  describe "builds on missing repository" do
    before  { get("/v3/repo/999999999999999/builds")       }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "builds on public repository, private API" do
    before  { Travis.config.private_api = true      }
    before  { get("/v3/repo/#{repo.id}/builds")            }
    after   { Travis.config.private_api = false     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "builds on private repository, not authenticated" do
    before  { repo.update_attribute(:private, true)  }
    before  { get("/v3/repo/#{repo.id}/builds")             }
    before  { repo.update_attribute(:private, false) }
    example { expect(last_response).to be_not_found  }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "builds private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/builds?limit=1", {}, headers)                           }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to be == {
      "@type"              => "builds",
      "@href"              => "/v3/repo/1/builds?limit=1",
      "@pagination"        => {
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 3,
        "is_first"         => true,
        "is_last"          => false,
        "next"             => {
          "@href"          => "/v3/repo/1/builds?limit=1&offset=1",
          "offset"         => 1,
          "limit"          => 1 },
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/1/builds?limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/1/builds?limit=1&offset=2",
          "offset"         => 2,
          "limit"          => 1 }},
      "builds"             => [{
        "@type"            => "build",
        "@href"            => "/v3/build/#{build.id}",
        "id"               => build.id,
        "number"           => "3",
        "state"            => "configured",
        "duration"         => nil,
        "event_type"       => "push",
        "previous_state"   => "passed",
        "started_at"       => "2010-11-12T13:00:00Z",
        "finished_at"      =>nil,
        "repository"       => {
          "@type"          => "repository",
          "@href"          => "/v3/repo/1",
          "id"             => 1,
          "slug"           => "svenfuchs/minimal"},
        "branch"           => {
          "@type"          => "branch",
          "@href"          => "/v3/repo/1/branch/master",
          "name"           => "master",
          "last_build"     => {
            "@href"        => "/v3/build/#{build.id}"}},
        "commit"           => {
          "@type"          => "commit",
          "id"             => 5,
          "sha"            => "add057e66c3e1d59ef1f",
          "ref"            => "refs/heads/master",
          "message"        => "unignore Gemfile.lock",
          "compare_url"    => "https://github.com/svenfuchs/minimal/compare/master...develop",
          "committed_at"   => "2010-11-12T12:55:00Z"}}]
    }}
  end

  describe "builds on private repository, private API, authenticated as user without access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: User.find(2), app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                          }}
    before        { repo.update_attribute(:private, true)                               }
    before        { get("/v3/repo/#{repo.id}/builds", {}, headers)                             }
    before        { repo.update_attribute(:private, false)                              }
    example       { expect(last_response).to be_not_found                               }
    example       { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "builds on private repository, authenticated as internal application with full access" do
    let(:app_name)   { 'travis-example'                                                           }
    let(:app_secret) { '12345678'                                                                 }
    let(:sign_opts)  { "a=#{app_name}"                                                            }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts)                   }
    let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}"            }}
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}


    before { repo.update_attribute(:private, true)   }
    before { get("/v3/repo/#{repo.id}/builds?limit=1", {}, headers) }
    before { repo.update_attribute(:private, false)  }


    example { expect(last_response).to be_ok   }
    example { expect(parsed_body).to be == {
      "@type"              => "builds",
      "@href"              => "/v3/repo/1/builds?limit=1",
      "@pagination"        => {
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 3,
        "is_first"         => true,
        "is_last"          => false,
        "next"             => {
          "@href"          => "/v3/repo/1/builds?limit=1&offset=1",
          "offset"         => 1,
          "limit"          => 1 },
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/1/builds?limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/1/builds?limit=1&offset=2",
          "offset"         => 2,
          "limit"          => 1 }},
      "builds"             => [{
        "@type"            => "build",
        "@href"            => "/v3/build/#{build.id}",
        "id"               => build.id,
        "number"           => "3",
        "state"            => "configured",
        "duration"         => nil,
        "event_type"       => "push",
        "previous_state"   => "passed",
        "started_at"       => "2010-11-12T13:00:00Z",
        "finished_at"      =>nil,
        "repository"       => {
          "@type"          => "repository",
          "@href"          => "/v3/repo/1",
          "id"             => 1,
          "slug"           => "svenfuchs/minimal"},
        "branch"           => {
          "@type"          => "branch",
          "@href"          => "/v3/repo/1/branch/master",
          "name"           => "master",
          "last_build"     => {
            "@href"        => "/v3/build/#{build.id}"}},
        "commit"           => {
          "@type"          => "commit",
          "id"             => 5,
          "sha"            => "add057e66c3e1d59ef1f",
          "ref"            => "refs/heads/master",
          "message"        => "unignore Gemfile.lock",
          "compare_url"    => "https://github.com/svenfuchs/minimal/compare/master...develop",
          "committed_at"   => "2010-11-12T12:55:00Z"}}]
    }}
  end

  describe "builds on private repository, authenticated as internal application with full access, but scoped to a different org" do
    let(:app_name)   { 'travis-example'                                                           }
    let(:app_secret) { '12345678'                                                                 }
    let(:sign_opts)  { "a=#{app_name}:s=travis-pro"                                               }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts)                   }
    let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}"            }}
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}

    before { repo.update_attribute(:private, true)   }
    before { get("/v3/repo/#{repo.id}/builds", {}, headers) }
    before { repo.update_attribute(:private, false)  }

    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "builds on private repository, authenticated as internal application with full access, scoped to the right org" do
    let(:app_name)   { 'travis-example'                                                           }
    let(:app_secret) { '12345678'                                                                 }
    let(:sign_opts)  { "a=#{app_name}:s=#{repo.owner_name}"                                       }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts)                   }
    let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}"            }}
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}


    before { repo.update_attribute(:private, true)   }
    before { get("/v3/repo/#{repo.id}/builds?limit=1", {}, headers) }
    before { repo.update_attribute(:private, false)  }


    example { expect(last_response).to be_ok   }
    example { expect(parsed_body).to be == {
      "@type"              => "builds",
      "@href"              => "/v3/repo/1/builds?limit=1",
      "@pagination"        => {
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 3,
        "is_first"         => true,
        "is_last"          => false,
        "next"             => {
          "@href"          => "/v3/repo/1/builds?limit=1&offset=1",
          "offset"         => 1,
          "limit"          => 1 },
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/1/builds?limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/1/builds?limit=1&offset=2",
          "offset"         => 2,
          "limit"          => 1 }},
      "builds"             => [{
        "@type"            => "build",
        "@href"            => "/v3/build/#{build.id}",
        "id"               => build.id,
        "number"           => "3",
        "state"            => "configured",
        "duration"         => nil,
        "event_type"       => "push",
        "previous_state"   => "passed",
        "started_at"       => "2010-11-12T13:00:00Z",
        "finished_at"      =>nil,
        "repository"       => {
          "@type"          => "repository",
          "@href"          => "/v3/repo/1",
          "id"             => 1,
          "slug"           => "svenfuchs/minimal"},
        "branch"           => {
          "@type"          => "branch",
          "@href"          => "/v3/repo/1/branch/master",
          "name"           => "master",
          "last_build"     => {
            "@href"        => "/v3/build/#{build.id}"}},
        "commit"           => {
          "@type"          => "commit",
          "id"             => 5,
          "sha"            => "add057e66c3e1d59ef1f",
          "ref"            => "refs/heads/master",
          "message"        => "unignore Gemfile.lock",
          "compare_url"    => "https://github.com/svenfuchs/minimal/compare/master...develop",
          "committed_at"   => "2010-11-12T12:55:00Z"}}]
    }}
  end

  describe "including non-existing field" do
    before  { get("/v3/repo/#{repo.id}/builds?include=repository.owner,repository.last_build_number") }
    example { expect(last_response.status).to be == 400 }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "no field \"repository.last_build_number\" to include"
    }}
  end

  describe "wrong include format" do
    before  { get("/v3/repo/#{repo.id}/builds?include=repository.last_build.branch") }
    example { expect(last_response.status).to be == 400 }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "illegal format for include parameter"
    }}
  end
end
