describe Travis::API::V3::Services::Cron::Delete, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:branch) { Travis::API::V3::Models::Branch.where(repository_id: repo).first }
  let(:cron)  { Travis::API::V3::Models::Cron.create(branch: branch, interval:'daily') }
  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
  let(:parsed_body) { JSON.load(body) }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe "deleting a cron job by id" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before     { delete("/v3/cron/#{cron.id}", {}, headers) }
    example    { expect(last_response.status).to eq 204 }
    example    { expect(Travis::API::V3::Models::Cron.where(id: cron.id)).to be_empty }
    example    { expect(parsed_body).to be_nil }
  end

  describe "try deleting a cron job without login" do
    before     { delete("/v3/cron/#{cron.id}") }
    example    { expect(Travis::API::V3::Models::Cron.where(id: cron.id)).to exist }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    })}
  end

  describe "try deleting a cron job with a user without permissions" do
    let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: false) }
    before     { delete("/v3/cron/#{cron.id}", {}, headers) }
    example    { expect(Travis::API::V3::Models::Cron.where(id: cron.id)).to exist }
    example    { expect(parsed_body).to eql_json({
        "@type"               => "error",
        "error_type"          => "insufficient_access",
        "error_message"       => "operation requires delete access to cron",
        "resource_type"       => "cron",
        "permission"          => "delete",
        "cron"                => {
            "@type"           => "cron",
            "@href"           => "/v3/cron/#{cron.id}",
            "@representation" => "minimal",
            "id"              => cron.id }
    })}
  end

  describe "try deleting a non-existing cron job" do
    before  { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: false) }
    before  { delete("/v3/cron/999999999999999", {}, headers) }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "cron not found (or insufficient access)",
      "resource_type" => "cron"
    })}
  end

  context do
    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
      before { delete("/v3/cron/#{cron.id}", {}, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before  { repo.update(migration_status: "migrated") }
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
      before { delete("/v3/cron/#{cron.id}", {}, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
