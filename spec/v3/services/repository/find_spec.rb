require 'spec_helper'

describe Travis::API::V3::Services::Repository::Find do
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  describe "public repository" do
    before     { get("/v3/repo/#{repo.id}")     }
    example    { expect(last_response).to be_ok }
    example    { expect(JSON.load(body)).to be == {
      "@type"           => "repository",
      "@href"           => "/v3/repo/#{repo.id}",
      "id"              =>  repo.id,
      "name"            =>  "minimal",
      "slug"            =>  "svenfuchs/minimal",
      "description"     => nil,
      "github_language" => nil,
      "active"          => true,
      "private"         => false,
      "owner"           => {
        "@type"         => "user",
        "id"            => repo.owner_id,
        "login"         => "svenfuchs" },
      "last_build"      => {
        "@type"         => "build",
        "@href"         => "/v3/build/#{repo.last_build_id}",
        "id"            => repo.last_build_id,
        "number"        => "2",
        "state"         => "passed",
        "duration"      => nil,
        "started_at"    => "2010-11-12T12:30:00Z",
        "finished_at"   => "2010-11-12T12:30:20Z"},
      "default_branch"  => {
        "@type"         => "branch",
        "@href"         => "/v3/repo/#{repo.id}/branch/master",
        "name"          => "master",
        "last_build"    => {
          "@type"       => "build",
          "@href"       => "/v3/build/#{repo.last_build.id}",
          "id"          => repo.last_build.id,
          "number"      => "3",
          "state"       => "configured",
          "duration"    => nil,
          "started_at"  => "2010-11-12T13:00:00Z",
          "finished_at" => nil}}
    }}
  end

  describe "missing repository" do
    before  { get("/v3/repo/999999999999999")       }
    example { expect(last_response).to be_not_found }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "public repository, private API" do
    before  { Travis.config.private_api = true      }
    before  { get("/v3/repo/#{repo.id}")            }
    after   { Travis.config.private_api = false     }
    example { expect(last_response).to be_not_found }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "private repository, not authenticated" do
    before  { repo.update_attribute(:private, true)  }
    before  { get("/v3/repo/#{repo.id}")             }
    before  { repo.update_attribute(:private, false) }
    example { expect(last_response).to be_not_found  }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}", {}, headers)                           }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(JSON.load(body)).to be == {
      "@type"           => "repository",
      "@href"           => "/v3/repo/#{repo.id}",
      "id"              =>  repo.id,
      "name"            =>  "minimal",
      "slug"            =>  "svenfuchs/minimal",
      "description"     => nil,
      "github_language" => nil,
      "active"          => true,
      "private"         => true,
      "owner"           => {
        "@type"         => "user",
        "id"            => repo.owner_id,
        "login"         => "svenfuchs" },
      "last_build"      => {
        "@type"         => "build",
        "@href"         => "/v3/build/#{repo.last_build_id}",
        "id"            => repo.last_build_id,
        "number"        => "2",
        "state"         => "passed",
        "duration"      => nil,
        "started_at"    => "2010-11-12T12:30:00Z",
        "finished_at"   => "2010-11-12T12:30:20Z"},
      "default_branch"  => {
        "@type"         => "branch",
        "@href"         => "/v3/repo/#{repo.id}/branch/master",
        "name"          => "master",
        "last_build"    => {
          "@type"       => "build",
          "@href"       => "/v3/build/#{repo.last_build.id}",
          "id"          => repo.last_build.id,
          "number"      => "3",
          "state"       => "configured",
          "duration"    => nil,
          "started_at"  => "2010-11-12T13:00:00Z",
          "finished_at" => nil}}
    }}
  end

  describe "private repository, private API, authenticated as user without access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: User.find(2), app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                          }}
    before        { repo.update_attribute(:private, true)                               }
    before        { get("/v3/repo/#{repo.id}", {}, headers)                             }
    before        { repo.update_attribute(:private, false)                              }
    example       { expect(last_response).to be_not_found                               }
    example       { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "private repository, authenticated as internal application with full access" do
    let(:app_name)   { 'travis-example'                                                           }
    let(:app_secret) { '12345678'                                                                 }
    let(:sign_opts)  { "a=#{app_name}"                                                            }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts)                   }
    let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}"            }}
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}


    before { repo.update_attribute(:private, true)   }
    before { get("/v3/repo/#{repo.id}", {}, headers) }
    before { repo.update_attribute(:private, false)  }


    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"           => "repository",
      "@href"           => "/v3/repo/#{repo.id}",
      "id"              =>  repo.id,
      "name"            =>  "minimal",
      "slug"            =>  "svenfuchs/minimal",
      "description"     => nil,
      "github_language" => nil,
      "active"          => true,
      "private"         => true,
      "owner"           => {
        "@type"         => "user",
        "id"            => repo.owner_id,
        "login"         => "svenfuchs" },
      "last_build"      => {
        "@type"         => "build",
        "@href"         => "/v3/build/#{repo.last_build_id}",
        "id"            => repo.last_build_id,
        "number"        => "2",
        "state"         => "passed",
        "duration"      => nil,
        "started_at"    => "2010-11-12T12:30:00Z",
        "finished_at"   => "2010-11-12T12:30:20Z"},
      "default_branch"  => {
        "@type"         => "branch",
        "@href"         => "/v3/repo/#{repo.id}/branch/master",
        "name"          => "master",
        "last_build"    => {
          "@type"       => "build",
          "@href"       => "/v3/build/#{repo.last_build.id}",
          "id"          => repo.last_build.id,
          "number"      => "3",
          "state"       => "configured",
          "duration"    => nil,
          "started_at"  => "2010-11-12T13:00:00Z",
          "finished_at" => nil}}
    }}
  end

  describe "private repository, authenticated as internal application with full access, but scoped to a different org" do
    let(:app_name)   { 'travis-example'                                                           }
    let(:app_secret) { '12345678'                                                                 }
    let(:sign_opts)  { "a=#{app_name}:s=travis-pro"                                               }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts)                   }
    let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}"            }}
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}

    before { repo.update_attribute(:private, true)   }
    before { get("/v3/repo/#{repo.id}", {}, headers) }
    before { repo.update_attribute(:private, false)  }

    example { expect(last_response).to be_not_found }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "private repository, authenticated as internal application with full access, scoped to the right org" do
    let(:app_name)   { 'travis-example'                                                           }
    let(:app_secret) { '12345678'                                                                 }
    let(:sign_opts)  { "a=#{app_name}:s=#{repo.owner_name}"                                       }
    let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts)                   }
    let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}"            }}
    before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}


    before { repo.update_attribute(:private, true)   }
    before { get("/v3/repo/#{repo.id}", {}, headers) }
    before { repo.update_attribute(:private, false)  }


    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"           => "repository",
      "@href"           => "/v3/repo/#{repo.id}",
      "id"              =>  repo.id,
      "name"            =>  "minimal",
      "slug"            =>  "svenfuchs/minimal",
      "description"     => nil,
      "github_language" => nil,
      "active"          => true,
      "private"         => true,
      "owner"           => {
        "@type"         => "user",
        "id"            => repo.owner_id,
        "login"         => "svenfuchs" },
      "last_build"      => {
        "@type"         => "build",
        "@href"         => "/v3/build/#{repo.last_build_id}",
        "id"            => repo.last_build_id,
        "number"        => "2",
        "state"         => "passed",
        "duration"      => nil,
        "started_at"    => "2010-11-12T12:30:00Z",
        "finished_at"   => "2010-11-12T12:30:20Z"},
      "default_branch"  => {
        "@type"         => "branch",
        "@href"         => "/v3/repo/#{repo.id}/branch/master",
        "name"          => "master",
        "last_build"    => {
          "@type"       => "build",
          "@href"       => "/v3/build/#{repo.last_build.id}",
          "id"          => repo.last_build.id,
          "number"      => "3",
          "state"       => "configured",
          "duration"    => nil,
          "started_at"  => "2010-11-12T13:00:00Z",
          "finished_at" => nil}}
    }}
  end
end