describe Travis::API::V3::Services::Jobs::Find, set_app: true do
  def create(type, attributes = {})
    FactoryGirl.create(type, attributes)
  end

  let!(:repo1)   { create(:repository, owner: user) }
  let!(:repo2)   { create(:repository, owner: user) }
  let!(:build1)  { create(:build, repository: repo1) }
  let!(:build2)  { create(:build, repository: repo2, sender_id: other_user.id, sender_type: 'User') }
  let!(:other_repo) { create(:repository) }
  let!(:other_build) { create(:build, repository: other_repo) }
  let!(:user)    { create(:user) }
  let!(:other_user) { create(:user, login: 'a-feminist') }
  let(:parsed_body) { JSON.load(body) }

  before do
    Travis::API::V3::Models::Permission.create!(user: user, repository: repo1)
    Travis::API::V3::Models::Permission.create!(user: user, repository: repo2)
  end

  describe 'for current user' do
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    it 'returns jobs that belong to current user' do
      get("/v3/jobs", {}, headers)

      job_ids = parsed_body['jobs'].map { |j| j['id'] }
      expect(job_ids).to eq([build2.matrix.first.id, build1.matrix.first.id])
    end

    it 'returns jobs sent by a user when created_by is passed' do
      get("/v3/jobs?created_by=a-feminist", {}, headers)

      job_ids = parsed_body['jobs'].map { |j| j['id'] }
      expect(job_ids).to eq([build2.matrix.first.id])
    end

    context "with active jobs" do
      before do
        build1.matrix.first.update_attributes(state: 'started')
      end

      it "returns only active jobs when active=true is passed" do
        get("/v3/jobs?active=true", {}, headers)

        job_ids = parsed_body['jobs'].map { |j| j['id'] }
        expect(job_ids).to eq([build1.matrix.first.id])
      end
    end
  end
end
