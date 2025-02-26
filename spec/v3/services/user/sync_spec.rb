describe Travis::API::V3::Services::User::Sync, set_app: true do
  let(:user)  { Travis::API::V3::Models::User.find_by_login('svenfuchs') }
  let(:user2) { Travis::API::V3::Models::User.create(login: 'carlad', is_syncing: true) }
  let(:sidekiq_payload) { Sidekiq::Client.last['args'].map! {|m| JSON.parse(m)} }
  let(:sidekiq_params)  { Sidekiq::Client.last['args'].last.deep_symbolize_keys }

  before do
    user.update_attribute(:is_syncing, false)
    allow(Travis::Features).to receive(:owner_active?).and_return(true)
    allow(Travis::Features).to receive(:owner_active?).with(:read_only_disabled, user).and_return(true)
    allow(Travis::Features).to receive(:owner_active?).with(:read_only_disabled, user2).and_return(true)
    @original_sidekiq = Sidekiq::Client
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = []
    stub_request(:post,  'http://billingfake.travis-ci.com/usage/stats').
          with(body: "{\"owners\":[{\"id\":1,\"type\":\"User\"}],\"query\":\"trial_allowed\"}")
      .to_return(status: 200, body: "{\"trial_allowed\": false }", headers: {})
  end

  after do
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = @original_sidekiq
  end

  describe "not authenticated" do
    before  { post("/v3/user/#{user.id}/sync") }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.parse(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  describe "missing user, authenticated" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { post("/v3/user/9999999999/sync", {}, headers) }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.parse(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "user not found (or insufficient access)",
      "resource_type" => "user"
    }}
  end

  describe "existing user, matches current user " do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { Travis::API::V3::Models::Permission.create(user: user) }
    before        { post("/v3/user/#{user.id}/sync", params, headers) }

    example { expect(last_response.status).to be == 200 }
    example { expect(JSON.parse(body).to_s).to include(
      "@type",
      "user",
      "@href",
      "@representation",
      "sync",
      "is_syncing",
      "id",
      "true")
    }

    example { expect(sidekiq_payload).to be == ['sync_user', 'user_id' => 1] }

    example { expect(Sidekiq::Client.last['queue']).to be == :sync                        }
    example { expect(Sidekiq::Client.last['class']).to be == 'Travis::GithubSync::Worker' }
  end

  describe "existing user, current user does not have sync access " do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { Travis::API::V3::Models::Permission.create(user: user) }
    before        { post("/v3/user/#{user2.id}/sync", params, headers) }

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.parse(body)).to be == {
      "@type"         => "error",
      "error_type"    => "insufficient_access",
      "error_message" => "operation requires sync access to user",
      "resource_type" => "user",
      "permission"    => "sync",
      "user"          => {
        "@type"       => "user",
        "@href"       => "/v3/user/#{user2.id}",
        "@representation"=> "minimal",
        "id"          => user2.id,
        'vcs_type'    => user2.vcs_type,
        "login"       => "carlad",
        "name"        => user2.name,
        "ro_mode"     => false
      }
    }}
  end

  describe "existing user, current user in read-only mode " do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before { Travis::API::V3::Models::Permission.create(user: user) }
    before { allow(Travis::Features).to receive(:owner_active?).with(:read_only_disabled, user).and_return(false) }
    before { post("/v3/user/#{user.id}/sync", params, headers) }

    example { expect(last_response.status).to be == 404 }
  end

  describe "existing user, authorized, user already syncing " do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: user2, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { Travis::API::V3::Models::Permission.create(user: user) }
    before        { post("/v3/user/#{user2.id}/sync", params, headers) }

    example { expect(last_response.status).to be == 409 }
    example { expect(JSON.parse(body)).to be == {
      "@type"         => "error",
      "error_type"    => "already_syncing",
      "error_message" => "sync already in progress"
      }
    }
  end
end
