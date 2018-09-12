describe Travis::API::V3::Services::Repository::Deactivate, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  before do
    repo.update_attributes!(active: true)
  end

  describe "not authenticated" do
    before  { post("/v3/repo/#{repo.id}/deactivate")      }
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
    before        { post("/v3/repo/9999999999/deactivate", {}, headers)                 }

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
    before        { post("/v3/repo/#{repo.id}/deactivate", {}, headers)                 }

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "error_type",
      "insufficient_access",
      "error_message",
      "operation requires deactivate access to repository",
      "resource_type",
      "repository",
      "permission",
      "deactivate")
    }
  end

  describe "private repository, no access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { repo.update_attribute(:private, true)                             }
    before        { post("/v3/repo/#{repo.id}/deactivate", {}, headers)                 }
    after         { repo.update_attribute(:private, false)                            }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "existing repository, admin and push access" do
    let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

    before do
      stub_request(:get, "https://api.github.com/repos/#{repo.slug}/hooks?per_page=100").to_return(
        status: 200, body: JSON.dump(
          [
            { name: 'travis', _links: { self: { href: "https://api.github.com/repos/#{repo.slug}/hooks/123" } } },
            { name: 'web', _links: { self: { href: "https://api.github.com/repos/#{repo.slug}/hooks/456" } } }
          ]
        )
      )
      stub_request(:delete, "https://api.github.com/repos/#{repo.slug}/hooks/123") # Remove service hook
      stub_request(:patch, "https://api.github.com/repos/#{repo.slug}/hooks/456")  # Set webhook
    end

    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, push: true) }
    before { post("/v3/repo/#{repo.id}/deactivate", {}, headers) }

    example { expect(last_response.status).to eq 200 }
    example do
      expect(JSON.load(body)).to include(
        '@type' => 'repository',
        'active' => false
      )
    end
  end
end
