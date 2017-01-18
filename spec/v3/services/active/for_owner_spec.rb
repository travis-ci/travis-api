require 'spec_helper'

RSpec::Matchers.define :contain_builds do |*builds|
  match do |response|
    response = JSON.parse(response.body)
    @returned = response['builds'].map { |b| b['id'] }
    builds.map(&:id).all? { |id| @returned.include?(id) }
  end
  failure_message_for_should { |_| "expected response #{@returned} to contain builds #{builds.map(&:id)}" }
end

RSpec::Matchers.define :not_contain_builds do |*builds|
  match do |response|
    response = JSON.parse(response.body)
    @returned = response['builds'].map { |b| b['id'] }
    builds.map(&:id).none? { |id| @returned.include?(id) }
  end
  failure_message_for_should { |_| "expected response #{@returned} not to contain builds #{builds.map(&:id)}" }
end

RSpec::Matchers.define :contain_jobs do |*jobs|
  match do |response|
    response = JSON.parse(response.body)
    @returned = response['builds'].flat_map { |b| b['jobs'] }.map { |j| j['id'] }
    jobs.map(&:id).all? { |id| @returned.include?(id) }
  end
  failure_message_for_should { |_| "expected response #{@returned} to contain jobs #{jobs.map(&:id)}" }
end

RSpec::Matchers.define :not_contain_jobs do |*jobs|
  match do |response|
    response = JSON.parse(response.body)
    @returned = response['builds'].flat_map { |b| b['jobs'] }.map { |j| j['id'] }
    jobs.map(&:id).none? { |id| @returned.include?(id) }
  end
  failure_message_for_should { |_| "expected response #{@returned} not to contain jobs #{jobs.map(&:id)}" }
end

RSpec.describe Travis::API::V3::Services::Active::ForOwner, set_app: true do
  V3 = Travis::API::V3

  let(:json_headers) { { 'HTTP_ACCEPT' => 'application/json' } }

  context 'not authenticated' do
    let(:user)       { FactoryGirl.create(:user, name: 'Joe', login: 'joe') }
    let(:user_repo)  { V3::Models::Repository.create(owner: user, name: 'Kneipe') }
    let(:user_build) { V3::Models::Build.create(repository: user_repo, owner: user, state: 'created') }
    let!(:user_job)  { V3::Models::Job.create(source_id: user_build.id, source_type: 'Build', owner: user, state: 'queued') }

    let(:private_repo)  { V3::Models::Repository.create(name: 'private-repo', owner: user, private: true) }
    let(:private_build) { V3::Models::Build.create(repository: private_repo, owner: user, state: 'created') }
    let!(:private_job)  { V3::Models::Job.create(source_id: private_build.id, source_type: 'Build', owner: user, state: 'queued') }

    let(:org)       { V3::Models::Organization.create(name: 'Spätkauf', login: 'spaetkauf') }
    let(:org_repo)  { V3::Models::Repository.create(owner: org, name: 'Bionade') }
    let(:org_build) { V3::Models::Build.create(repository: org_repo, owner: org, state: 'created') }
    let!(:org_job)  { V3::Models::Job.create(source_id: org_build.id, source_type: 'Build', owner: org, state: 'queued') }
    
    describe 'viewing a user' do
      before { get("/v3/owner/#{user.login}/active?include=build.jobs", {}, json_headers) }

      example { expect(last_response).to be_ok }
      example { expect(last_response).to contain_builds user_build }
      example { expect(last_response).to contain_jobs user_job }

      example { expect(last_response).to not_contain_builds private_build }
      example { expect(last_response).to not_contain_jobs private_job }
    end

    describe 'viewing an org' do
      before { get("/v3/owner/#{org.login}/active?include=build.jobs", {}, json_headers) }

      example { expect(last_response).to be_ok }
      example { expect(last_response).to contain_builds org_build }
      example { expect(last_response).to contain_jobs org_job }
    end
  end

  context 'authenticated' do
    let(:user)       { FactoryGirl.create(:user, name: 'Joe', login: 'joe') }
    let(:user_repo)  { V3::Models::Repository.create(owner: user, name: 'Kneipe') }
    let(:user_build) { V3::Models::Build.create(repository: user_repo, owner: user, state: 'created') }
    let!(:user_job)  { V3::Models::Job.create(source_id: user_build.id, source_type: 'Build', owner: user, state: 'queued') }

    let(:user_token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }

    let(:private_repo)  { V3::Models::Repository.create(name: 'private-repo', owner: user, private: true) }
    let(:private_build) { V3::Models::Build.create(repository: private_repo, owner: user, state: 'created') }
    let!(:private_job)  { V3::Models::Job.create(source_id: private_build.id, source_type: 'Build', owner: user, state: 'queued') }
    let!(:private_perm) { V3::Models::Permission.create(repository: private_repo, user: user) }

    context 'viewing own profile' do
      describe 'can see builds for all own repos' do
        before { get("/v3/owner/#{user.login}/active?include=build.jobs", {}, json_headers.merge('HTTP_AUTHORIZATION' => "token #{user_token}")) }

        example { expect(last_response).to be_ok }
        example { expect(last_response).to contain_builds user_build, private_build }
        example { expect(last_response).to contain_jobs user_job, private_job }
      end
    end

    context 'viewing another user' do
      let(:other_user)  { FactoryGirl.create(:user) }
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
      let!(:perm_job)  { V3::Models::Job.create(source_id: perm_build.id, source_type: 'Build', owner: org, state: 'queued') }
      let!(:user_perm) { V3::Models::Permission.create(repository: perm_repo, user: user) }

      let(:non_perm_repo)  { V3::Models::Repository.create(owner: org, name: 'Bionade', private: true) }
      let(:non_perm_build) { V3::Models::Build.create(repository: non_perm_repo, owner: org, state: 'created') }
      let!(:non_perm_job)  { V3::Models::Job.create(source_id: non_perm_build.id, source_type: 'Build', owner: org, state: 'queued') }

      describe 'can see everything public or that you have permissions for' do
        before { get("/v3/owner/#{org.login}/active?include=build.jobs", {}, json_headers.merge('HTTP_AUTHORIZATION' => "token #{user_token}")) }

        example { expect(last_response).to be_ok }
        example { expect(last_response).to contain_builds perm_build }
        example { expect(last_response).to contain_jobs perm_job }

        example { expect(last_response).to not_contain_builds non_perm_build }
        example { expect(last_response).to not_contain_jobs non_perm_job }
      end
    end
  end
end
