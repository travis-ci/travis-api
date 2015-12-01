require 'spec_helper'

describe Travis::API::V3::Services::Repository::Unstar do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  # before do
  #   Travis::API::V3::Models::Star.create(user_id: repo.owner_id, repository_id: repo.id)
  # end

  describe "not authenticated" do
    before  { post("/v3/repo/#{repo.id}/unstar")      }
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
    before        { post("/v3/repo/9999999999/unstar", {}, headers)                 }

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
    before        { post("/v3/repo/#{repo.id}/unstar", {}, headers)                 }

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "error_type",
      "insufficient_access",
      "error_message",
      "operation requires unstar access to repository",
      "resource_type",
      "repository",
      "permission",
      "unstar")
    }
  end

  describe "private repository, no access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { repo.update_attribute(:private, true)                             }
    before        { post("/v3/repo/#{repo.id}/unstar", {}, headers)                 }
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
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)                          }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                                 }}
    let(:star) { Travis::API::V3::Models::Star.create(user_id: repo.owner_id, repository_id: repo.id) }
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before        { post("/v3/repo/#{repo.id}/unstar", params, headers)                                      }
    after         { star.delete }

    example { expect(last_response.status).to be == 200 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "star",
      "@href",
      "@representation",
      "minimal",
      "false",
      "id")
    }
    example { expect(Travis::API::V3::Models::Star.where(user_id: repo.owner_id, repository_id: repo.id)).to be == []}
  end  
end
