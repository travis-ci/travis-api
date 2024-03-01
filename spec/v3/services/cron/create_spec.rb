describe Travis::API::V3::Services::Cron::Create, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:branch) { Travis::API::V3::Models::Branch.where(repository_id: repo).first }
  let(:non_existing_branch) { Travis::API::V3::Models::Branch.create(repository: repo, name: 'cron-test', exists_on_github: false) }
  let(:last_cron) {Travis::API::V3::Models::Cron.where(branch_id: branch.id).last}
  let(:current_cron) {Travis::API::V3::Models::Cron.where(branch_id: branch.id).last}
  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}", "Content-Type" => "application/json" }}
  let(:options) {{ "interval" => "monthly", "dont_run_if_recent_build_exists" => false }}
  let(:options2) {{ "cron.interval" => "monthly", "cron.dont_run_if_recent_build_exists" => false }}
  let(:wrong_options) {{ "interval" => "notExisting", "dont_run_if_recent_build_exists" => false }}
  let(:parsed_body) { JSON.load(body) }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe "creating a cron job" do
    before     { last_cron }
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before     { post("/v3/repo/#{repo.id}/branch/#{branch.name}/cron", options, headers) }
    example    { expect(current_cron == last_cron).to be_falsey }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to eql_json({
        "@type"               => "cron",
        "@href"               => "/v3/cron/#{current_cron.id}",
        "@representation"     => "standard",
        "@permissions"        => {
            "read"            => true,
            "delete"          => true,
            "start"           => true },
        "id"                  => current_cron.id,
        "repository"          => {
            "@type"           => "repository",
            "@href"           => "/v3/repo/#{repo.id}",
            "@representation" => "minimal",
            "id"              => repo.id,
            "name"            => "minimal",
            "slug"            => "svenfuchs/minimal" },
        "branch"              => {
            "@type"           => "branch",
            "@href"           => "/v3/repo/#{repo.id}/branch/#{branch.name}",
            "@representation" => "minimal",
            "name"            => "#{branch.name}" },
        "interval"            => "monthly",
        "dont_run_if_recent_build_exists"    => false,
        "last_run"            => current_cron.last_run,
        "next_run"      => current_cron.next_run.strftime('%Y-%m-%dT%H:%M:%SZ'),
        "created_at"          => current_cron.created_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
        "active"              => true,
    })}
    example { expect(current_cron.next_run).to_not be nil }
  end

  describe "creating a cron job with cron as param prefix" do
    before     { last_cron }
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before     { post("/v3/repo/#{repo.id}/branch/#{branch.name}/cron", options2, headers) }
    example    { expect(current_cron == last_cron).to be_falsey }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to eql_json({
        "@type"               => "cron",
        "@href"               => "/v3/cron/#{current_cron.id}",
        "@representation"     => "standard",
        "@permissions"        => {
            "read"            => true,
            "delete"          => true,
            "start"           => true },
        "id"                  => current_cron.id,
        "repository"          => {
            "@type"           => "repository",
            "@href"           => "/v3/repo/#{repo.id}",
            "@representation" => "minimal",
            "id"              => repo.id,
            "name"            => "minimal",
            "slug"            => "svenfuchs/minimal" },
        "branch"              => {
            "@type"           => "branch",
            "@href"           => "/v3/repo/#{repo.id}/branch/#{branch.name}",
            "@representation" => "minimal",
            "name"            => "#{branch.name}" },
        "interval"            => "monthly",
        "dont_run_if_recent_build_exists"    => false,
        "last_run"            => current_cron.last_run,
        "next_run"      => current_cron.next_run.strftime('%Y-%m-%dT%H:%M:%SZ'),
        "created_at"          => current_cron.created_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
        "active"              => true
    })}
    example { expect(current_cron.next_run).to_not be nil }
  end

  describe "creating multiple cron jobs for one branch" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before     { post("/v3/repo/#{repo.id}/branch/#{branch.name}/cron", options, headers) }
    before     { post("/v3/repo/#{repo.id}/branch/#{branch.name}/cron", options, headers) }
    it "only stores one" do
      expect(Travis::API::V3::Models::Cron.where(branch_id: branch.id).count).to eq(1)
    end
  end

  describe "creating a cron job with a wrong interval" do
    before     { last_cron }
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before     { post("/v3/repo/#{repo.id}/branch/#{branch.name}/cron", wrong_options, headers) }
    example    { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "error",
      "error_message" => "Invalid value for interval. Interval must be \"daily\", \"weekly\" or \"monthly\"!"
    })}
  end

  describe "creating a cron job on a branch not existing on GitHub" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before     { post("/v3/repo/#{repo.id}/branch/#{non_existing_branch.name}/cron", options, headers) }
    example    { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "error",
      "error_message" => "Crons can only be set up for branches existing on GitHub!"
    })}
  end

  describe "try creating a cron job without login" do
    before     { post("/v3/repo/#{repo.id}/branch/#{branch.name}/cron", options) }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    })}
  end

  describe "try creating a cron job with a user without permissions" do

    let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: false) }
    before     { post("/v3/repo/#{repo.id}/branch/#{branch.name}/cron", options, headers) }
    example    { expect(parsed_body).to eql_json({
        "@type"               => "error",
        "error_type"          => "insufficient_access",
        "error_message"       => "operation requires create_cron access to repository",
        "resource_type"       => "repository",
        "permission"          => "create_cron",
        "repository"          => {
            "@type"           => "repository",
            "@href"           => "/v3/repo/#{repo.id}",
            "@representation" => "minimal",
            "id"              => repo.id,
            "name"            => "minimal",
            "slug"            => "svenfuchs/minimal" }
    })}
  end

  describe "creating cron on a non-existing repository by slug" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: false) }
    before     { post("/v3/repo/svenfuchs%2Fminimal1/branch/master/cron", options, headers)     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    })}
  end

  describe "creating cron on a non-existing branch" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: false) }
    before     { post("/v3/repo/#{repo.id}/branch/hopefullyNonExistingBranch/cron", options, headers)     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "branch not found (or insufficient access)",
      "resource_type" => "branch"
    })}
  end

  context do
    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
      before { post("/v3/repo/#{repo.id}/branch/#{branch.name}/cron", options, headers) }

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
      before { post("/v3/repo/#{repo.id}/branch/#{branch.name}/cron", options, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
