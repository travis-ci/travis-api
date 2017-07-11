describe Travis::API::V3::Services::Request::Find, set_app: true do

  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:request) { repo.requests.first }

  describe "retrieve request on a public repository" do
    before     { get("/v3/repo/#{repo.id}/request/#{request.id}")     }
    example    { expect(last_response).to be_ok }
    example    { expect(JSON.load(body).to_s).to include(
                  "@type",
                  "request",
                  "/v3/repo/#{repo.id}/request",
                  "id",
                  "state",
                  "message",
                  "result",
                  "builds",
                  "@representation",
                  "repository",
                  "owner",
                  "event_type",
                  "push")
    }
  end

  describe "retrieve request on private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/request/#{request.id}", {}, headers)                             }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(JSON.load(body).to_s).to include(
                      "@type",
                      "request",
                      "/v3/repo/#{repo.id}/request",
                      "id",
                      "state",
                      "message",
                      "result",
                      "builds",
                      "@representation",
                      "repository",
                      "owner",
                      "event_type",
                      "push")
    }

  end
end
