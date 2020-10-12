describe Travis::Api::App::Endpoint::Repos, set_app: true do
  include Support::S3

  context 'correctly capture params' do
    before do
      described_class.get('/spec/match/((?<id>\d+)|(?<owner_name>[^\/]+))', mustermann_opts: { type: :regexp }) do
        params[:id] ? "id" : "name"
      end
    end

    it 'matches :id with digits' do
      expect(get('/repos/spec/match/123').body).to eq("id")
    end

    it 'does not match :id with non-digits' do
      expect(get('/repos/spec/match/f123').body).to eq("name")
    end
  end

  context 'caches endpoints' do
    let(:user) { FactoryBot.create(:user) }
    let(:repo) { FactoryBot.create(:repository, private: false, owner_name: 'user', name: 'repo') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:cache_options) {{ s3: { bucket_name: '' , access_key_id: '', secret_access_key: ''} }}

    before { Travis.config.cache_options = cache_options }

    context 'with authorized users' do
      before { user.permissions.create(repository_id: repo.id, push: true) }

      it 'responds with 200' do
        expect(get("/repos/#{repo.id}/caches", cache_options, headers).status).to eq(200)
        expect(delete("/repos/#{repo.id}/caches", cache_options, headers).status).to eq(200)
        expect(get("/repos/#{repo.owner_name}/#{repo.name}/caches", cache_options, headers).status).to eq(200)
        expect(delete("/repos/#{repo.owner_name}/#{repo.name}/caches", cache_options, headers).status).to eq(200)
      end
    end

    context 'with unauthorized users' do
      before { user.permissions.create(repository_id: repo.id, push: false) }

      it 'responds with 403' do
        expect(get("/repos/#{repo.id}/caches", cache_options, headers).status).to eq(403)
        expect(delete("/repos/#{repo.id}/caches", cache_options, headers).status).to eq(403)
        expect(get("/repos/#{repo.owner_name}/#{repo.name}/caches", cache_options, headers).status).to eq(403)
        expect(delete("/repos/#{repo.owner_name}/#{repo.name}/caches", cache_options, headers).status).to eq(403)
      end
    end
  end
end
