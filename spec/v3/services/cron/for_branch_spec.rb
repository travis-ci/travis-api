describe Travis::API::V3::Services::Cron::ForBranch, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:branch) { Travis::API::V3::Models::Branch.where(repository_id: repo).first }
  let(:cron)  { Travis::API::V3::Models::Cron.create(branch: branch, interval:'daily') }
  let(:parsed_body) { JSON.load(body) }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe "fetching all crons by repo id" do
    before     { cron }
    before     { get("/v3/repo/#{repo.id}/branch/#{branch.name}/cron")     }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to eql_json({
      "@type"               => "cron",
      "@href"               => "/v3/cron/#{cron.id}",
      "@representation"     => "standard",
      "@permissions"        => {
          "read"            => true,
          "delete"          => false,
          "start"           => true },
      "id"                  => cron.id,
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
          "name"            => branch.name },
      "interval"            => "daily",
      "dont_run_if_recent_build_exists"    => false,
      "last_run"            => cron.last_run,
      "next_run"            => cron.next_run.strftime('%Y-%m-%dT%H:%M:%SZ'),
      "created_at"          => cron.created_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
      "active"              => true,
    })}
  end

  describe "fetching crons on a non-existing repository by slug" do
    before  { get("/v3/repo/svenfuchs%2Fminimal1/branch/master/cron") }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    })}
  end

  describe "fetching crons on a non-existing branch" do
    before  { get("/v3/repo/#{repo.id}/branch/hopefullyNonExistingBranch/cron") }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "branch not found (or insufficient access)",
      "resource_type" => "branch"
    })}
  end

  describe "fetching crons from private repo, not authenticated" do
    before  { repo.update_attribute(:private, true)  }
    before  { get("/v3/repo/#{repo.id}/branch/#{branch.name}/cron") }
    after   { repo.update_attribute(:private, false) }
    example { expect(last_response).to be_not_found  }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    })}
  end

end
