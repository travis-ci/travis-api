require 'spec_helper'

RSpec::Matchers.define :contain_builds do |*builds|
  match do |response|
    response = JSON.parse(response.body)
    returned = response['builds'].map { |b| b['id'] }
    builds.map(&:id).all? { |id| returned.include?(id) }
  end
end

RSpec::Matchers.define :contain_jobs do |*jobs|
  match do |response|
    response = JSON.parse(response.body)
    returned = response['builds'].flat_map { |b| b['jobs'] }.map { |j| j['id'] }
    jobs.map(&:id).all? { |id| returned.include?(id) }
  end
end

RSpec.describe Travis::API::V3::Services::Active::ForOwner, set_app: true do
  V3 = Travis::API::V3

  let(:json_headers) { { 'HTTP_ACCEPT' => 'application/json' } }

  context 'not authenticated' do
    let(:user)       { FactoryGirl.create(:user, name: 'Joe', login: 'joe') }
    let(:user_repo)  { V3::Models::Repository.create(owner: user, name: 'Kneipe') }
    let(:user_build) { V3::Models::Build.create(repository: user_repo, owner: user, state: 'created') }
    let!(:user_job)  { V3::Models::Job.create(source_id: user_build.id, source_type: 'Build', owner: user, state: 'queued') }

    let(:org)       { V3::Models::Organization.create(name: 'Spätkauf', login: 'spaetkauf') }
    let(:org_repo)  { V3::Models::Repository.create(owner: org, name: 'Bionade') }
    let(:org_build) { V3::Models::Build.create(repository: org_repo, owner: org, state: 'created') }
    let!(:org_job)  { V3::Models::Job.create(source_id: org_build.id, source_type: 'Build', owner: org, state: 'queued') }
    
    describe 'viewing a user' do
      before { get("/v3/owner/#{user.login}/active?include=build.jobs", {}, json_headers) }

      example { expect(last_response).to be_ok }
      example { expect(last_response).to contain_builds user_build }
      example { expect(last_response).to contain_jobs user_job }
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
    
    let(:other_user)  { FactoryGirl.create(:user) }
    let(:other_repo)  { V3::Models::Repository.create(name: 'another-repo', owner: other_user) }
    let(:other_build) { V3::Models::Build.create(repository: other_repo, owner: other_user, state: 'created') }
    let!(:other_job)  { V3::Models::Job.create(source_id: other_build.id, source_type: 'Build', owner: other_user, state: 'queued') }

    context 'viewing own profile' do
      describe 'can see builds for own repo, and builds for other repo with permissions' do
        before do
          V3::Models::Permission.create(repository: other_repo, user: user, pull: true)
          get("/v3/owner/#{user.login}/active?include=build.jobs", {}, json_headers.merge('HTTP_AUTHORIZATION' => "token #{user_token}"))
        end

        example { expect(last_response).to be_ok }
        example { expect(last_response).to contain_builds user_build, other_build }
        example { expect(last_response).to contain_jobs user_job, other_job }
      end
    end

    describe 'viewing profile of another user'
    # can see anything public

    describe 'viewing an org as member'
    # can see everything

    describe 'viewing another org'
    # can see anything public
  end
end
