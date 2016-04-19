require 'spec_helper'

describe Travis::API::V3::Services::Requests::Find do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:request) { repo.requests.first }

  describe "fetching requests on a public repository" do
    before     { get("/v3/repo/#{repo.id}/requests")     }
    example    { expect(last_response).to be_ok }
    example    { expect(JSON.load(body).to_s).to include(
                  "@type",
                  "requests",
                  "/v3/repo/#{repo.id}/requests",
                  "repository",
                  "commit",
                  "message",
                  "the commit message",
                  "branch_name",
                  "representation",
                  "@pagination",
                  "owner",
                  "created_at",
                  "result",
                  "sha",
                  "svenfuchs/minimal",
                  "event_type",
                  "push")
    }
  end

  describe "fetching requests on private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/requests", {}, headers)                             }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(JSON.load(body).to_s).to include(
                    "@type",
                    "requests",
                    "/v3/repo/#{repo.id}/requests",
                    "repository",
                    "commit",
                    "message",
                    "the commit message",
                    "branch_name",
                    "representation",
                    "@pagination",
                    "owner",
                    "created_at",
                    "result",
                    "sha",
                    "svenfuchs/minimal",
                    "event_type",
                    "push")
    }

  end
end
