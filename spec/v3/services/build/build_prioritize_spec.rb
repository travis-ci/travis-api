describe Travis::API::V3::Services::Build::BuildPrioritize, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:owner) { FactoryBot.create(:org) }
  let(:priority) { { high: 5, low: -5, medium: nil } }

  before do
    allow(Travis::Features).to receive(:owner_active?).and_return(true)
    allow(Travis::Features).to receive(:owner_active?).with(:enqueue_to_hub, repo.owner).and_return(false)
  end

  describe "not authenticated" do
    before { get("/v3/build/#{build.id}/build_prioritize") }
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
    before        { get("/v3/build/9999999999/build_prioritize", {}, headers) }

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
    before { get("/v3/build/#{build.id}/build_prioritize", {}, headers) }
    after { repo.update_attribute(:private, false) }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    } }
  end

  describe "existing build, check permissions" do
    let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { "HTTP_AUTHORIZATION" => "token #{token}" } }
    before do
      Travis::Features.activate_owner(:build_priorities_org, owner)
      build.update_attributes(owner_id: owner.id, owner_type: 'Organization')
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)
      build.jobs.update_all(priority: priority[:high])
      get("/v3/build/#{build.id}/build_prioritize", {}, headers)
    end
    example { expect(build.owner.build_priority?).to be_truthy }
    example { expect(build.priority_high?).to be_truthy}
    example { expect(last_response.status).to be == 200 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "build",
      "priority_status",
      "build_priority_permission")
    }
  end
end
