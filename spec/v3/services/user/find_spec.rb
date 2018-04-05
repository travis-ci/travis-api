describe Travis::API::V3::Services::User::Find, set_app: true do
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }
  let(:installation) { Travis::API::V3::Models::Installation.new(owner_id: user.id, owner_type: 'User', github_installation_id: 123) }

  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                  }}

  before { user.save! }
  before { installation.save!}

  describe "authenticated as user with access" do
    before  { get("/v3/user/#{user.id}", {}, headers) }
    example { expect(last_response).to be_ok          }
    example { expect(JSON.load(body)).to be ==        {
      "@type"            => "user",
      "@href"            => "/v3/user/#{user.id}",
      "@representation"  => "standard",
      "@permissions"     => {"read"=>true, "sync"=>true},
      "id"               => user.id,
      "login"            => "svenfuchs",
      "name"             =>"Sven Fuchs",
      "github_id"        => user.github_id,
      "avatar_url"       => "https://0.gravatar.com/avatar/07fb84848e68b96b69022d333ca8a3e2",
      "github_installation_id"=>installation.github_installation_id,
      "is_syncing"       => user.is_syncing,
      "synced_at"        => user.synced_at
    }}
  end
end
