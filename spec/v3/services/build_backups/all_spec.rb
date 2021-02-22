describe Travis::API::V3::Services::BuildBackups::All, set_app: true do
  let(:parsed_body) { JSON.parse(last_response.body) }

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/build_backups')

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

    it 'responds with list of build_backups' do
      get('/v3/build_backups', { repository_id: repository.id }, headers)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json({
        '@type' => 'build_backups',
        '@pagination' => {
          'limit' => 25,
          'offset' => 0,
          'count' => 1,
          'is_first' => true,
          'is_last' => true,
          'next' => nil,
          'prev' => nil,
          'first' => {
            '@href' => "/v3/build_backups?repository_id=#{repository.id}",
            'offset' => 0,
            'limit' => 25
          },
          'last' => {
            '@href' => "/v3/build_backups?repository_id=#{repository.id}",
            'offset' => 0,
            'limit' => 25
          }
        },
        '@representation' => 'standard',
        '@href' => "/v3/build_backups?repository_id=#{repository.id}",
        'build_backups' => [{
          '@type' => 'build_backup',
          '@representation' => 'standard',
          '@href' => "/v3/build_backup/#{build_backup.id}",
          'file_name' => build_backup.file_name,
          'created_at' => build_backup.created_at.iso8601
        }]
      })
    end
  end
end
