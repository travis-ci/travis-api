describe Travis::API::V3::Services::Accounts::ForCurrentUser, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
  before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
  before        { repo.update_attribute(:private, true)                             }
  after         { repo.update_attribute(:private, false)                            }

  let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org', github_id: 42)   }
  before    { org.save!                                               }
  before    { org.memberships.create(user: repo.owner)                }
  after     { org.delete                                              }

  describe "authenticated as user with access" do
    before  { get("/v3/accounts", {}, headers) }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"               => "accounts",
      "@href"               => "/v3/accounts",
      "@representation"     => "standard",
      "accounts"            => [{
        "@type"             => "account",
        "@representation"   =>"standard",
        "@permissions"      => { "read"=>true },
        "id"                => repo.owner.github_id,
        "subscribed"        => false,
        "educational"       => false,
        "owner"             => {
          "@type"           => "user",
          "@href"           => "/v3/user/#{repo.owner_id}",
          "@representation" =>"minimal",
          "id"              => repo.owner_id,
          "login"           => "svenfuchs" }},
       {"@type"             => "account",
        "@representation"   => "standard",
        "@permissions"      => { "read"=>true },
        "id"                => 42,
        "subscribed"        => false,
        "educational"       => false,
        "owner"             => {
          "@type"           => "organization",
          "@href"           => "/v3/org/#{org.id}",
          "@representation" => "minimal",
          "id"              => org.id,
          "login"           => "example-org"}
      }]
    }}
  end
end
