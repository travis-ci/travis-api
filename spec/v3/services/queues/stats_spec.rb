describe Travis::API::V3::Services::Queues::Stats, set_app: true do

  describe 'jobs stats' do
    let(:repo)  { FactoryBot.create(:repository, name: 'travis-web') }

    before do
      FactoryBot.create(:job, repository: repo, queue: 'builds.linux', state: 'queued')
      FactoryBot.create(:job, repository: repo, queue: 'builds.linux', state: 'queued')
      FactoryBot.create(:job, repository: repo, queue: 'builds.linux', state: 'started')
    end

    context 'when authenticated by user token' do
      let(:user)    { FactoryBot.create(:user) }
      let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
      let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

      it 'renders error' do
        get("/v3/queues/builds.linux/stats", {}, headers)
        expect(parsed_body['error_message']).to eql('login required')
      end
    end

    context 'when authenticated by internal token' do
      let(:token) { Travis.config.applications[:autoscaler][:token] }
      let(:headers) { { 'HTTP_AUTHORIZATION' => "internal autoscaler:#{token}" } }

      before do
        Travis.config.applications[:autoscaler] = { token: 'sometoken', full_access: true }
      end

      after do
        Travis.config.applications.delete(:autoscaler)
      end

      it 'returns jobs stats by state' do
        get("/v3/queues/builds.linux/stats", {}, headers)

        expect(parsed_body['started']).to eql(1)
        expect(parsed_body['queued']).to eql(2)
        expect(parsed_body['queue_name']).to eql('builds.linux')
      end
    end
  end
end
