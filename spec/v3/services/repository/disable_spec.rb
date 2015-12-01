require 'spec_helper'

describe Travis::API::V3::Services::Repository::Disable do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  before do
    repo.update_attributes!(active: true)
    Travis::Features.stubs(:owner_active?).returns(true)
  end

  describe "not authenticated" do
    before  { post("/v3/repo/#{repo.id}/disable")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  describe "missing repo, authenticated" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/repo/9999999999/disable", {}, headers)                 }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "existing repository, no push access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/repo/#{repo.id}/disable", {}, headers)                 }

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "error_type",
      "insufficient_access",
      "error_message",
      "operation requires disable access to repository",
      "resource_type",
      "repository",
      "permission",
      "disable")
    }
  end

  describe "private repository, no access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { repo.update_attribute(:private, true)                             }
    before        { post("/v3/repo/#{repo.id}/disable", {}, headers)                 }
    after         { repo.update_attribute(:private, false)                            }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "existing repository, push access" do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)                     }
    let(:headers) {{ 'Http-Authorization' => "token #{token}"                                            }}
    let(:uri) { "/v3/repo/#{repo.id}/disable" }

    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true, admin: true) }
    before        { stub_request(:get, "https://api.github.com/repos/svenfuchs/minimal/hooks?per_page=100").
         with(:headers => {'Accept'=>'application/vnd.github.v3+json,application/vnd.github.beta+json;q=0.5,application/json;q=0.1', 'Accept-Charset'=>'utf-8', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'token github_oauth_token', 'Origin'=>'travis-ci.org', 'User-Agent'=>'Travis-API/3 Travis-CI/0.0.1 GH/0.14.0'}).
         to_return(:status => 202, :body => "hello", :headers => {}) }
    before        { stub_request(:post, "http://v3/repo/1/disable").
         with(:headers => headers) }
    before        { post(uri) }

    example { expect(last_response.status).to be == 202 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "cxxxxxxxxxx",
      "@href",
      "@representation",
      "minimal",
      "disable",
      "id",
      "xxxxxxxxxxx")
    }

  end


end
