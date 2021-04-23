describe Travis::API::V3::Services::BuildBackup::Find, set_app: true do
  let(:parsed_body) { JSON.parse(last_response.body) }

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/build_backup/1')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:repository) { FactoryBot.create(:repository, owner: user) }
    let!(:build_backup) { FactoryBot.create(:build_backup, repository: repository) }
    let(:organization) { FactoryBot.create(:org, login: 'travis') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    let(:content) { '123' }

    before do
      stub_request(:post, 'https://www.googleapis.com/oauth2/v4/token').
        to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, /o\/#{build_backup.file_name}\?alt=media/).
        to_return(status: 200, body: content, headers: { 'Content-Type' => 'application/json' })
    end

    it 'responds with build_backup' do
      get("/v3/build_backup/#{build_backup.id}", {}, headers)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json({
        '@type' => 'build_backup',
        '@representation' => 'standard',
        '@href' => "/v3/build_backup/#{build_backup.id}",
        'file_name' => build_backup.file_name,
        'created_at' => build_backup.created_at.iso8601
      })
    end

    context 'when text/plain Accept header is present' do
      before { headers['HTTP_ACCEPT'] = 'text/plain' }

      it 'responds with content' do
        get("/v3/build_backup/#{build_backup.id}", {}, headers)

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq(content)
      end
    end

    context 'when txt extension is present' do
      it 'responds with content' do
        get("/v3/build_backup/#{build_backup.id}.txt", {}, headers)

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq(content)
      end
    end
  end
end
