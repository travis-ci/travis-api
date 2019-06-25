describe Travis::Api::App::Endpoint::Repos, set_app: true do
  include Support::S3

  context 'correctly capture params' do
    before do
      described_class.get('/spec/match/:id')   { "id"   }
      described_class.get('/spec/match/:name') { "name" }
    end

    it 'matches :id with digits' do
      get('/repos/spec/match/123').body.should be == "id"
    end

    it 'does not match :id with non-digits' do
      get('/repos/spec/match/f123').body.should be == "name"
    end
  end

  context 'unauthorized users on caches endpoints' do
    let(:user) { Factory.create(:user) }
    let(:repo) { Factory.create(:repository, private: false, owner_name: 'user', name: 'repo') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:cache_options) {{ s3: { bucket_name: '' , access_key_id: '', secret_access_key: ''} }}

    before { Travis.config.cache_options = cache_options }
    before { user.permissions.create(repository_id: repo.id, push: false) }

    subject { @response }

    describe 'GET /repos/:id/caches' do
      before { @response = get("/repos/#{repo.id}/caches", cache_options, headers) }

      its(:status) { should == 403 }
    end

    describe 'DELETE /repos/:id/caches' do
      before { @response = delete("/repos/#{repo.id}/caches", cache_options, headers) }

      its(:status) { should == 403 }
    end

    describe 'GET /repos/:owner_name/:name/caches' do
      before { @response = get("/repos/#{repo.owner_name}/#{repo.name}/caches", cache_options, headers) }

      its(:status) { should == 403 }
    end
  end
end
