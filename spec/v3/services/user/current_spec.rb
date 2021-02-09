describe Travis::API::V3::Services::User::Current, set_app: true do
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }

  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                  }}

  describe "authenticated as user with access" do
    before  { get("/v3/user", {}, headers)     }
    before  { allow(Travis::Features).to receive(:owner_active?).with(:read_only_disabled, user).and_return(true) }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"            => "user",
      "@href"            => "/v3/user/#{user.id}",
      "@representation"  => "standard",
      "@permissions"     => {"read"=>true, "sync"=>true},
      "id"               => user.id,
      "login"            => "svenfuchs",
      "name"             => "Sven Fuchs",
      "email"            => "sven@fuchs.com",
      "github_id"        => user.github_id,
      "vcs_id"           => user.vcs_id,
      "vcs_type"         => user.vcs_type,
      "avatar_url"       => "https://0.gravatar.com/avatar/07fb84848e68b96b69022d333ca8a3e2",
      "is_syncing"       => user.is_syncing,
      "synced_at"        => user.synced_at,
      "education"        => nil,
      "allow_migration"  => false,
      "allowance"        => {
        "@type"                 => "allowance",
        "@representation"       => "minimal",
        "id"                    => user.id
      },
      "recently_signed_up"=>false,
      "secure_user_hash" => nil,
      "ro_mode" => false
    }}
  end
end
