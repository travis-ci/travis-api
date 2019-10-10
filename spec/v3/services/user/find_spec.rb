describe Travis::API::V3::Services::User::Find, set_app: true do
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }

  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                  }}

  let(:hmac_key) { 'USER_HASH_SECRET_KEY' }
  let(:secure_user_hash) { OpenSSL::HMAC.hexdigest('sha256', hmac_key, user.id.to_s) }

  before do
    user.education = true
    user.save!

    Travis.config.intercom = {
      hmac_secret_key: hmac_key
    }
  end

  after do
    Travis.config.intercom = nil
  end

  describe "authenticated as user with access" do
    before  { get("/v3/user/#{user.id}", {}, headers) }
    example { expect(last_response).to be_ok          }
    example { expect(JSON.load(body)).to be ==        {
      "@type"              => "user",
      "@href"              => "/v3/user/#{user.id}",
      "@representation"    => "standard",
      "@permissions"       => {"read"=>true, "sync"=>true},
      "id"                 => user.id,
      "login"              => "svenfuchs",
      "name"               =>"Sven Fuchs",
      "github_id"          => user.github_id,
      "avatar_url"         => "https://0.gravatar.com/avatar/07fb84848e68b96b69022d333ca8a3e2",
      "is_syncing"         => user.is_syncing,
      "synced_at"          => user.synced_at,
      "education"          => true,
      "allow_migration"    => false,
      "first_logged_in_at" => user.first_logged_in_at,
      "secure_user_hash"   => secure_user_hash,
    }}
  end
end
