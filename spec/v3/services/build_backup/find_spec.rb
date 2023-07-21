describe Travis::API::V3::Services::BuildBackup::Find, set_app: true do
  let(:parsed_body) { JSON.parse(last_response.body) }

  let(:gcs_json_bucket_response) {
    %q{
      {"kind": "storage#bucket",
       "selfLink":  "https://www.googleapis.com/storage/v1/b/travis-cache-staging-org-gce",
        "name": "travis-cache-production-org-gce",
        "id": "travis-cache-staging-org-gce/25736446"
      }
    }
  }

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
      stub_request(:post, "https://oauth2.googleapis.com/token").
        to_return(:status => 200, :body => "{}", :headers => {"Content-Type" => "application/json"})
      stub_request(:get,%r((.+))).with(
        headers: { 'Metadata-Flavor'=>'Google', 'User-Agent'=>'Ruby'}
        ).to_return(status: 200, body: "", headers: {})

      stub_request(:get, %r((.+)travis-cache-production-org-gce\?alt=media)).
        to_return(status: 200, body: content, headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, %r((.+)/o\/#{build_backup.file_name}\?alt=media/)).
        to_return(status: 200, body: content, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://storage.googleapis.com/storage/v1/b/fillme").
        to_return(:status => 200, :body => gcs_json_bucket_response, :headers => {"Content-Type" => "application/json"})
      stub_request(:get, "https://storage.googleapis.com/storage/v1/b/travis-cache-production-org-gce/o/#{build_backup.file_name}").
        to_return(:status => 200, :body => gcs_json_bucket_response, :headers => {"Content-Type" => "application/json"})
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
