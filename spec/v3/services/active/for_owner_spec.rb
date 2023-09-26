require 'spec_helper'

RSpec::Matchers.define :contain_builds do |*builds|
  match do |response|
    response = JSON.parse(response.body)
    @returned = response['builds'].map { |b| b['id'] }
    builds.map(&:id).all? { |id| @returned.include?(id) }
  end
  failure_message { |_| "expected response #{@returned} to contain builds #{builds.map(&:id)}" }
end

RSpec::Matchers.define :not_contain_builds do |*builds|
  match do |response|
    response = JSON.parse(response.body)
    @returned = response['builds'].map { |b| b['id'] }
    builds.map(&:id).none? { |id| @returned.include?(id) }
  end
  failure_message { |_| "expected response #{@returned} not to contain builds #{builds.map(&:id)}" }
end

RSpec::Matchers.define :contain_jobs do |*jobs|
  match do |response|
    response = JSON.parse(response.body)
    @returned = response['builds'].flat_map { |b| b['jobs'] }.map { |j| j['id'] }
    jobs.map(&:id).all? { |id| @returned.include?(id) }
  end
  failure_message { |_| "expected response #{@returned} to contain jobs #{jobs.map(&:id)}" }
end

RSpec::Matchers.define :contain_full_jobs do
  match do |response|
    response = JSON.parse(response.body)
    @response = response['builds'].flat_map { |b| b['jobs'] }
    @response.all? { |j| j["@representation"] == "standard" }
  end
  failure_message { |_| "expected response #{@response} to contain for jobs: '@representation' => 'standard'"}
end

RSpec::Matchers.define :contain_minimal_jobs do
  match do |response|
    response = JSON.parse(response.body)
    @response = response['builds'].flat_map { |b| b['jobs'] }
    @response.all? { |j| j["@representation"] == "minimal" }
  end
  failure_message { |_| "expected response #{@response} to contain for jobs: '@representation' => 'minimal'"}
end

RSpec::Matchers.define :not_contain_jobs do |*jobs|
  match do |response|
    response = JSON.parse(response.body)
    @returned = response['builds'].flat_map { |b| b['jobs'] }.map { |j| j['id'] }
    jobs.map(&:id).none? { |id| @returned.include?(id) }
  end
  failure_message { |_| "expected response #{@returned} not to contain jobs #{jobs.map(&:id)}" }
end

RSpec.describe Travis::API::V3::Services::Active::ForOwner, set_app: true do
  V3 = Travis::API::V3

  let(:json_headers) { { 'HTTP_ACCEPT' => 'application/json' } }

  context 'not authenticated' do
    let(:user)       { FactoryBot.create(:user, name: 'Joe', login: 'joe') }
    let(:user_repo)  { V3::Models::Repository.create(owner: user, name: 'Kneipe', owner_type: 'User') }
    let(:user_build) { V3::Models::Build.create(repository: user_repo, owner: user, state: 'created', owner_type: 'User') }
    let!(:user_job)  { V3::Models::Job.create(source_id: user_build.id, source_type: 'Build', owner: user, state: 'queued', repository: user_repo, owner_type: 'User') }
    let!(:err_job)   { V3::Models::Job.create(source_id: user_build.id, source_type: 'Build', owner: user, state: 'errored', repository: user_repo, owner_type: 'User') }

    let(:private_repo)  { V3::Models::Repository.create(name: 'private-repo', owner: user, private: true) }
    let(:private_build) { V3::Models::Build.create(repository: private_repo, owner: user, state: 'created') }
    let!(:private_job)  { V3::Models::Job.create(source_id: private_build.id, source_type: 'Build', owner: user, state: 'queued', repository: private_repo) }

    let(:org)       { V3::Models::Organization.create(name: 'Spätkauf', login: 'spaetkauf') }
    let(:org_repo)  { V3::Models::Repository.create(owner: org, name: 'Bionade') }
    let(:org_build) { V3::Models::Build.create(repository: org_repo, owner: org, state: 'created') }
    let!(:org_job)  { V3::Models::Job.create(source_id: org_build.id, source_type: 'Build', owner: org, state: 'queued', repository: org_repo) }

    let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

    before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

    describe 'in public mode' do
      before { Travis.config[:public_mode] = true }

      describe 'viewing a user' do
        before { get("/v3/owner/#{user.login}/active?include=build.jobs", {}, json_headers) }

        example { expect(last_response).to be_ok }
        example { expect(last_response).to contain_builds user_build }
        example { expect(last_response).to contain_jobs user_job }

        example { expect(last_response).to not_contain_builds private_build }
        example { expect(last_response).to not_contain_jobs err_job, private_job }
      end

      describe 'viewing an org' do
        before { get("/v3/owner/#{org.login}/active?include=build.jobs", {}, json_headers) }

        example { expect(last_response).to be_ok }
        example { expect(last_response).to contain_builds org_build }
        example { expect(last_response).to contain_jobs org_job }
      end
    end

    describe 'in private mode' do
      before { Travis.config[:public_mode] = false }

      describe 'viewing a user' do
        before { get("/v3/owner/#{user.login}/active?include=build.jobs", {}, json_headers) }

        example { expect(last_response).to be_ok }
        example { expect(last_response).to_not contain_builds user_build }
        example { expect(last_response).to_not contain_jobs user_job }

        # TODO it seems like the body is empty, but the spec still fails
        xexample { expect(last_response).to_not not_contain_builds private_build }
        xexample { expect(last_response).to_not not_contain_jobs err_job, private_job }
      end

      describe 'viewing an org' do
        before { get("/v3/owner/#{org.login}/active?include=build.jobs", {}, json_headers) }

        example { expect(last_response).to be_ok }
        example { expect(last_response).to_not contain_builds org_build }
        example { expect(last_response).to_not contain_jobs org_job }
      end
    end
  end

  context 'authenticated' do
    let(:user)       { FactoryBot.create(:user, name: 'Joe', login: 'joe') }
    let(:user_repo)  { V3::Models::Repository.create(owner: user, name: 'Kneipe', owner_type: 'User') }
    let(:user_build) { V3::Models::Build.create(repository: user_repo, owner: user, state: 'created', owner_type: 'User') }
    let!(:user_job)  { V3::Models::Job.create(source_id: user_build.id, source_type: 'Build', owner: user, state: 'queued', repository: user_repo, owner_type: 'User') }

    let(:user_token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }

    let(:private_repo)  { V3::Models::Repository.create(name: 'private-repo', owner: user, private: true, owner_type: 'User') }
    let(:private_build) { V3::Models::Build.create(repository: private_repo, owner: user, state: 'created', owner_type: 'User') }
    let!(:private_job)  { V3::Models::Job.create(source_id: private_build.id, source_type: 'Build', owner: user, state: 'queued', repository: private_repo, owner_type: 'User') }
    let!(:private_perm) { V3::Models::Permission.create(repository: private_repo, user: user) }

    let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

    before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

    context 'viewing own profile' do
      describe 'can see builds for all own repos' do
        before { get("/v3/owner/#{user.login}/active?include=build.jobs", {}, json_headers.merge('HTTP_AUTHORIZATION' => "token #{user_token}")) }

        example { expect(last_response).to be_ok }
        example { expect(last_response).to contain_builds user_build, private_build }
        example { expect(last_response).to contain_jobs user_job, private_job }
      end
    end

    context 'viewing another user' do
      let(:other_user)  { FactoryBot.create(:user) }
      let(:other_token) { Travis::Api::App::AccessToken.create(user: other_user, app_id: 1) }

      describe 'can see anything public' do
        before { get("/v3/owner/#{user.login}/active?include=build.jobs", {}, json_headers.merge('HTTP_AUTHORIZATION' => "token #{other_token}")) }

        example { expect(last_response).to be_ok }
        example { expect(last_response).to contain_builds user_build }
        example { expect(last_response).to contain_jobs user_job }

        example { expect(last_response).to not_contain_builds private_build }
        example { expect(last_response).to not_contain_jobs private_job }
      end
    end

    context 'viewing an org' do
      let(:org)       { V3::Models::Organization.create(name: 'Spätkauf', login: 'spaetkauf') }

      let(:perm_repo)  { V3::Models::Repository.create(owner: org, name: 'Bionade') }
      let(:perm_build) { V3::Models::Build.create(repository: perm_repo, owner: org, state: 'created') }
      let!(:perm_job)  { V3::Models::Job.create(source_id: perm_build.id, source_type: 'Build', owner: org, state: 'queued', repository: perm_repo, owner_type: 'Organization') }
      let!(:non_active_job) { V3::Models::Job.create(source_id: perm_build.id, source_type: 'Build', owner: org, state: 'finished', repository: perm_repo, owner_type: 'Organization') }
      let!(:user_perm) { V3::Models::Permission.create(repository: perm_repo, user: user) }

      let(:non_perm_repo)  { V3::Models::Repository.create(owner: org, name: 'Bionade', private: true) }
      let(:non_perm_build) { V3::Models::Build.create(repository: non_perm_repo, owner: org, state: 'created') }
      let!(:non_perm_job)  { V3::Models::Job.create(source_id: non_perm_build.id, source_type: 'Build', owner: org, state: 'queued', repository: non_perm_repo, owner_type: 'Organization') }

      describe 'can see everything public or that you have permissions for' do
        before { get("/v3/owner/#{org.login}/active?include=build.jobs", {}, json_headers.merge('HTTP_AUTHORIZATION' => "token #{user_token}")) }

        example { expect(last_response).to be_ok }
        example { expect(last_response).to contain_builds perm_build }
        example { expect(last_response).to contain_jobs perm_job }
        example { expect(last_response).to contain_full_jobs }

        example { expect(last_response).to not_contain_builds non_perm_build }
        example { expect(last_response).to not_contain_jobs non_perm_job }
        example { expect(last_response).to not_contain_jobs non_active_job }
      end

      describe 'can see everything (with minimal jobs) public or that you have permissions for' do
        before { get("/v3/owner/#{org.login}/active", {}, json_headers.merge('HTTP_AUTHORIZATION' => "token #{user_token}")) }

        example { expect(last_response).to be_ok }
        example { expect(last_response).to contain_builds perm_build }
        example { expect(last_response).to contain_jobs perm_job }
        example { expect(last_response).to contain_minimal_jobs }

        example { expect(last_response).to not_contain_builds non_perm_build }
        example { expect(last_response).to not_contain_jobs non_perm_job }
        example { expect(last_response).to not_contain_jobs non_active_job }
      end
    end
  end
end
