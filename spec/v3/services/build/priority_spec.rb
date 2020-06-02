describe Travis::API::V3::Services::Build::Priority, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:payload) { { "id" => "#{build.id}", "user_id" => 1, "source" => "api" } }

  before do
    allow(Travis::Features).to receive(:owner_active?).and_return(true)
    allow(Travis::Features).to receive(:owner_active?).with(:enqueue_to_hub, repo.owner).and_return(false)
    @original_sidekiq = Sidekiq::Client
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = []
  end

  after do
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = @original_sidekiq
  end

  describe "not authenticated" do
    before { post("/v3/build/#{build.id}/priority") }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    } }
  end

  describe "missing build, authenticated" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { "HTTP_AUTHORIZATION" => "token #{token}" } }
    before        { post("/v3/build/9999999999/priority", {}, headers) }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    } }
  end

  describe "private repository, no access" do
    let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { "HTTP_AUTHORIZATION" => "token #{token}" } }
    before { repo.update_attribute(:private, true) }
    before { post("/v3/build/#{build.id}/priority", {}, headers) }
    after { repo.update_attribute(:private, false) }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    } }
  end

  describe "existing build, priority set" do
    let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { "HTTP_AUTHORIZATION" => "token #{token}" } }
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before { post("/v3/build/#{build.id}/priority", {}, headers) }

    example { expect(last_response.status).to be == 202 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "build",
      "event_type",
      "priority")
    }
  end
end
