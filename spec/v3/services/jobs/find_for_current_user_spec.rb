describe Travis::API::V3::Services::Jobs::Find, set_app: true do
  def create(type, attributes = {})
    FactoryBot.create(type, attributes)
  end

  let!(:repo1)   { create(:repository_without_last_build, owner: user) }
  let!(:repo2)   { create(:repository_without_last_build, owner: user) }
  let!(:other_repo) { create(:repository) }
  let!(:other_build) { create(:build, repository: other_repo) }
  let!(:user)    { create(:user) }
  let!(:other_user) { create(:user, login: 'a-feminist') }
  let(:parsed_body) { JSON.load(body) }

  let!(:req1) { create(:request, repository: repo1) }
  let!(:commit1){ create(:commit, repository: repo1) }
  let(:build1) { Travis::API::V3::Models::Build.create(id: 111, repository: repo1, request: req1, sender_id: user.id, sender_type: 'User', owner: user, owner_type: 'User')}

  let!(:req2) { create(:request, repository: repo2) }
  let!(:commit2){ create(:commit, repository: repo2) }
  let(:build2) { Travis::API::V3::Models::Build.create(id: 222, repository: repo2, request: req2, sender_id: other_user.id, sender_type: 'User', owner: user, owner_type: 'User')}

  let(:job1) { Travis::API::V3::Models::Job.create(id: 111, repository: repo1, commit: commit1, source_id: build1.id, source_type: 'Build', owner: user, owner_type: 'User')}
  let(:job2) { Travis::API::V3::Models::Job.create(id: 222, repository: repo2, commit: commit2, source_id: build2.id, source_type: 'Build', owner: user, owner_type: 'User')}


  before do
    Travis::API::V3::Models::Permission.create!(user: user, repository: repo1)
    Travis::API::V3::Models::Permission.create!(user: user, repository: repo2)
     job1.reload
     job2.reload
  end

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe 'for current user' do
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    it 'returns jobs that belong to current user' do
      get("/v3/jobs", {}, headers)

      job_ids = parsed_body['jobs'].map { |j| j['id'] }
      expect(job_ids).to eq([build2.jobs.first.id, build1.jobs.first.id])
    end

    it 'returns jobs sent by a user when created_by is passed' do
      get("/v3/jobs?created_by=a-feminist", {}, headers)

      job_ids = parsed_body['jobs'].map { |j| j['id'] }
      expect(job_ids).to eq([build2.jobs.first.id])
    end

    context "with active jobs" do
      before do
        build1.jobs.first.update(state: 'started')
      end

      it "returns only active jobs when active=true is passed" do
        get("/v3/jobs?active=true", {}, headers)

        job_ids = parsed_body['jobs'].map { |j| j['id'] }
        expect(job_ids).to eq([build1.jobs.first.id])
      end
    end
  end
end
