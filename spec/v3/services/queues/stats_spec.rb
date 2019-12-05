describe Travis::API::V3::Services::Queues::Stats, set_app: true do
  let(:user)    { FactoryGirl.create(:user) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  describe 'jobs stats' do
    let(:repo)  { FactoryGirl.create(:repository, name: 'travis-web') }

    before do
      Factory.create(:job, repository: repo, queue: 'builds.linux', state: 'queued')
      Factory.create(:job, repository: repo, queue: 'builds.linux', state: 'queued')
      Factory.create(:job, repository: repo, queue: 'builds.linux', state: 'started')
    end

    it 'returns jobs stats by state' do
      get("/v3/queues/builds.linux/stats", {}, headers)

      expect(parsed_body['started']).to eql(1)
      expect(parsed_body['queued']).to eql(2)
    end
  end
end
