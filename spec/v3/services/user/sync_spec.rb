describe Travis::API::V3::Services::User::Sync, set_app: true do
  let(:user)  { Travis::API::V3::Models::User.find_by_login('svenfuchs') }
  let(:user2) { Travis::API::V3::Models::User.create(login: 'carlad', is_syncing: true) }
  let(:sidekiq_payload) { JSON.load(Sidekiq::Client.last['args'].to_json) }
  let(:sidekiq_params)  { Sidekiq::Client.last['args'].last.deep_symbolize_keys }

  before do
    user.update_attribute(:is_syncing, false)
    Travis::Features.stubs(:owner_active?).returns(true)
    @original_sidekiq = Sidekiq::Client
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = []
    ::Travis::RemoteVCS::User.any_instance.stubs(:sync) { true }
  end

  after do
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = @original_sidekiq
  end

  describe "not authenticated" do
    before  { post("/v3/user/#{user.id}/sync") }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
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
    example { expect(JSON.load(body)).to      be ==     {
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
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "user",
      "@href",
      "@representation",
      "sync",
      "is_syncing",
      "id",
      "true")
    }
  end

  describe "existing user, current user does not have sync access " do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { Travis::API::V3::Models::Permission.create(user: user) }
    before        { post("/v3/user/#{user2.id}/sync", params, headers) }

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to be == {
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
        "login"       => "carlad"
      }
    }}
  end

  describe "existing user, authorized, user already syncing " do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: user2, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { Travis::API::V3::Models::Permission.create(user: user) }
    before        { post("/v3/user/#{user2.id}/sync", params, headers) }

    example { expect(last_response.status).to be == 409 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "already_syncing",
      "error_message" => "sync already in progress"
      }
    }
  end
end
