describe Travis::API::V3::Services::Installation::Find, set_app: true do
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }
  let!(:installation) { Travis::API::V3::Models::Installation.create(owner_type: 'User', owner_id: user.id, github_id: 789) }

  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                  }}

  before { user.save! }

  describe "authenticated as user with access" do
    before  { get("/v3/installation/#{installation.github_id}", {}, headers) }
    example { expect(last_response).to be_ok          }
    example { expect(JSON.load(body)).to be ==        {
      "@type"            => "installation",
      "@href"            => "/v3/installation/#{installation.github_id}",
      "@representation"  => "standard",
      "id"               => installation.id,
      "github_id"        => installation.github_id,
      "owner"            => {
        "@type"=>"user",
        "@href"=>"/v3/user/#{user.id}",
        "@representation"=>"minimal",
        "id"=>user.id,
        "login"=>user.login,
        "vcs_type" => user.vcs_type,
        "name" => user.name
      }
    }}
  end

  describe "authenticated as user with access, including installation.owner" do
    before  { get("/v3/installation/#{installation.github_id}?include=installation.owner", {}, headers) }
    example { expect(last_response).to be_ok          }
    example { expect(JSON.load(body)).to be ==        {
      "@type"            => "installation",
      "@href"            => "/v3/installation/#{installation.github_id}",
      "@representation"  => "standard",
      "id"               => installation.id,
      "github_id"        => installation.github_id,
      "owner"            => {
        "@type" => "user",
        "@href" => "/v3/user/#{user.id}",
        "@representation" => "standard",
        "@permissions" => {
          "read" => true,
          "sync" => true
        },
        "id" => 1,
        "login" => user.login,
        "name" => user.name,
        "email" => "sven@fuchs.com",
        "github_id" => nil,
        "vcs_id" => user.vcs_id,
        "vcs_type" => user.vcs_type,
        "avatar_url" => "https://0.gravatar.com/avatar/07fb84848e68b96b69022d333ca8a3e2",
        "is_syncing" => nil,
        "synced_at" => nil,
        "education" => nil,
        "allowance"   => {
          "@representation"   => "minimal",
          "@type"             => "allowance",
          "concurrency_limit" => 1,
          "private_repos"     => false,
          "public_repos"      => true,
          "subscription_type" => 1,
          "user_usage" => false,
          "pending_user_licenses" => false,
          "id"                => 1
        },
        "allow_migration" => false,
        "recently_signed_up" => false,
        "secure_user_hash" => nil,
      }
    }}
  end
end
