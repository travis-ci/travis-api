describe Travis::API::V3::Services::Requests::Find, set_app: true do
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
                  "builds",
                  "sha",
                  "svenfuchs/minimal",
                  "event_type",
                  "push",
                  "base_commit",
                  "head_commit")
    }
    example 'reverse ordered' do
      expect(JSON.load(body)['requests'].map { |r| r['id'] }).to eq repo.requests.pluck(:id).sort.reverse
    end
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
                    "builds",
                    "sha",
                    "svenfuchs/minimal",
                    "event_type",
                    "push",
                    "base_commit",
                    "head_commit")
    }

  end

  describe "fetching requests with branch filter and non-existing branch" do
    before        { get("/v3/repo/#{repo.id}/requests?branch=main")                   }
    example do
      expect(last_response).to be_ok
      expect(JSON.load(body).to_s).to include('requests')
      expect(JSON.load(body)['requests'].count).to eq(0)
    end
  end

  describe "fetching requests with branch filter" do
    before  do
      repo.requests.first.update_attribute(:branch_id, repo.default_branch.id)
      get("/v3/repo/#{repo.id}/requests?branch=master")
    end
    example do
      expect(last_response).to be_ok
      expect(JSON.load(body).to_s).to include(
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
                    "builds",
                    "sha",
                    "svenfuchs/minimal",
                    "event_type",
                    "push",
                    "base_commit",
                    "head_commit")
      expect(JSON.load(body)['requests'].count).to eq(1)
    end
  end

  describe "fetching requests with request filter" do
    before do
      repo.requests.first.update_attribute(:result, 'rejected')
      get("/v3/repo/#{repo.id}/requests?result=rejected")
    end
    example do
      expect(last_response).to be_ok
      expect(JSON.load(body).to_s).to include('requests')
      expect(JSON.load(body)['requests'].count).to eq(1)
    end
  end
end
