describe Travis::API::V3::Services::Build::Priority, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:org) { Travis::API::V3::Models::Organization.create(login: 'travis-ci', name: 'travis-ci') }
  let(:priority) { { high: 5, low: -5, medium: nil } }
  let(:jobs) { Travis::API::V3::Models::Job.all}
  let(:payload) { { 'id'=> "#{build.id}", 'user_id' => 1, 'source' => 'api' } }

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
    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
      post("/v3/build/#{build.id}/priority", {}, headers)
    end

    example { expect(build.jobs.first.priority).to eq priority[:high] }
    example { expect(build.jobs.last.priority).to eq priority[:high] }
    example { expect(last_response.status).to be == 202 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "build",
      "event_type",
      "priority")
    }
  end

  describe "existing build, no associated jobs" do
    let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { "HTTP_AUTHORIZATION" => "token #{token}" } }

    before { build.jobs.delete_all }
    before { post("/v3/build/#{build.id}/priority", {}, headers) }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "Jobs are not found"
    } }
  end

  describe "existing repository, non priority build not found, not cancelable" do
    let(:params)  { { cancel_all: true } }
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before do
      build.update_attribute(:owner_type, "Organization")
      build.update_attribute(:owner_id, org.id)
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true, pull: true)
      allow(Travis::Features).to receive(:owner_active?).with(:enqueue_to_hub, repo.owner).and_return(true)
    end

    describe "started state" do
      before { build.update_attribute(:state, "started") }
      before { post("/v3/build/#{build.id}/priority", params, headers) }
      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "build",
        "@href",
        "@representation",
        "minimal",
        "id",
        "priority")
      }
    end

    describe "queued state" do
      before { build.update_attribute(:state, "queued") }
      before { post("/v3/build/#{build.id}/priority", params, headers) }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "build",
        "@href",
        "@representation",
        "minimal",
        "id",
        "priority")
      }
    end

    describe "received state" do
      before { build.update_attribute(:state, "received") }
      before { post("/v3/build/#{build.id}/priority", params, headers) }

      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "build",
        "@href",
        "@representation",
        "minimal",
        "id",
        "priority")
      }
    end 
  end

  describe "existing repository, non priority build, cancelable" do
    let(:params) { { cancel_all: true } }
    let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before do
      jobs.update_all(priority: priority[:low])
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true, pull: true)
      allow(Travis::Features).to receive(:owner_active?).with(:enqueue_to_hub, repo.owner).and_return(true)
    end

    describe "started state" do
      before { build.update_attribute(:state, "started") }
      before { post("/v3/build/#{build.id}/priority", params, headers) }
      example { expect(last_response.status).to be == 202 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "build",
        "@href",
        "@representation",
        "minimal",
        "id",
        "priority")
      }
    end
  end
end
