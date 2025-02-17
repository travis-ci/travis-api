describe Travis::API::V3::Services::User::Find, set_app: true, billing_spec_helper: true do
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }

  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                  }}
  
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }
  let(:paid_plans_count) { 1 }

  before do
    user.education = true
    user.save!
    Travis.config.host = 'travis-ci.com'
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
    stub_billing_request(:get, "/usage/users/#{user.id}/allowance", auth_key: billing_auth_key, user_id: user.id)
      .to_return(body: JSON.dump({ 'public_repos': true, 'private_repos': true, 'user_usage': true, 'pending_user_licenses': false, 'concurrency_limit': 666 }))
    stub_billing_request(:post, "/usage/stats", auth_key: billing_auth_key, user_id: user.id)
      .to_return(body: JSON.dump({ 'query': 'paid_plan_count', 'paid_plans': paid_plans_count }))
  end

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
      "name"             => "Sven Fuchs",
      "email"            => "sven@fuchs.com",
      "github_id"        => user.github_id,
      "vcs_id"           => user.vcs_id,
      "vcs_type"         => user.vcs_type,
      "avatar_url"       => "https://0.gravatar.com/avatar/07fb84848e68b96b69022d333ca8a3e2",
      "is_syncing"       => user.is_syncing,
      "synced_at"        => user.synced_at,
      "education"        => true,
      "allow_migration"  => false,
      "trial_allowed"    => false,
      "internal"         => false,
      "allowance"        => {
        "@type"                 => "allowance",
        "@representation"       => "minimal",
        "id"                    => user.id
      },
      "custom_keys" => [],
      "recently_signed_up"=>false,
      "secure_user_hash" => nil,
      "ro_mode" => false,
      "confirmed_at" => nil,
    }}
  end

  describe "authenticated as user with access ,collaboration status" do

    let(:paid_plans_count) { 1 }
    before  {
      get("/v3/user/#{user.id}?include=user.collaborator", {}, headers)

    }
    example {
      expect(last_response).to be_ok
    }
    example { expect(JSON.load(body)).to be ==        {
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
      "education"        => true,
      "allow_migration"  => false,
      "trial_allowed"    => false,
      "internal"         => false,
      "allowance"        => {
        "@type"                 => "allowance",
        "@representation"       => "minimal",
        "id"                    => user.id
      },
      "custom_keys" => [],
      "recently_signed_up"=>false,
      "secure_user_hash" => nil,
      "ro_mode" => false,
      "confirmed_at" => nil,
      'collaborator' => true
    }}
  end

  describe "authenticated as user with access ,collaboration status when user is not a collaborator" do
    let(:paid_plans_count) { 0 }
    before  {
      get("/v3/user/#{user.id}?include=user.collaborator", {}, headers)
    }

    example {
      expect(last_response).to be_ok
    }
    example { expect(JSON.load(body)).to be ==        {
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
      "education"        => true,
      "allow_migration"  => false,
      "trial_allowed"    => false,
      "internal"         => false,
      "allowance"        => {
        "@type"                 => "allowance",
        "@representation"       => "minimal",
        "id"                    => user.id
      },
      "custom_keys" => [],
      "recently_signed_up"=>false,
      "secure_user_hash" => nil,
      "ro_mode" => false,
      "confirmed_at" => nil,
      'collaborator' => false
    }}
  end
end
