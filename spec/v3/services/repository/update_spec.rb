describe Travis::API::V3::Services::Repository::Update, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  before { Travis.config.applications = { app: { full_access: true, token: '12345' } } }
  after  { Travis.config.applications = {} }

  describe "not authenticated" do
    before  { patch("/v3/repo/#{repo.id}", com_id: 1) }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  describe "authenticated" do
    let(:headers) { { 'HTTP_AUTHORIZATION' => "internal app:12345" } }
    before { patch("/v3/repo/#{repo.id}", { com_id: 1 }, headers) }

    example { expect(last_response.status).to be == 200 }
    example { expect(repo.reload.com_id).to eq 1 }
  end

  describe "authenticated, missing repo" do
    let(:headers) { { 'HTTP_AUTHORIZATION' => "internal app:12345" } }
    before { patch("/v3/repo/9999999999", { com_id: 1 }, headers) }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "authenticated as a user" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { patch("/v3/repo/#{repo.id}", { com_id: 1 }, headers) }

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "insufficient_access",
      "error_message" => "forbidden"
    }}
  end
end
