describe Travis::Api::App::Endpoint::Repos, set_app: true do
  include Support::S3

  let(:authorization) { { 'permissions' => ['repository_settings_create', 'repository_settings_update', 'repository_state_update', 'repository_settings_delete', 'repository_cache_view', 'repository_cache_delete'] } }
  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  context 'correctly capture params' do
    before do
      described_class.get('/spec/match/((?<id>\d+)|(?<owner_name>[^\/]+))', mustermann_opts: { type: :regexp }) do
        params[:id] ? "id" : "name"
      end
    end

    it 'matches :id with digits' do
      expect(get('/repos/spec/match/123').body).to eq("id")
    end

   # we tested same thing here ./spec/integration/visibility_spec.rb
   # and after gem upgrade Mustermann does not prevent :id
   # to be not be digit-only so solution for that is manual change in the code
    xit 'does not match :id with non-digits' do
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
  
  describe 'builds endpoint' do
    let(:user) { FactoryBot.create(:user) }
    let(:repo) { FactoryBot.create(:repository, private: false, owner_name: 'user', name: 'repo') }

    before { user.permissions.create(repository_id: repo.id, push: false) }

    context 'when user is authorizing with token' do
      context 'and token is not a RSS one' do
        let(:token) { user.tokens.asset.first }

        context 'and user has a RSS token' do
          it 'responds with 401' do
            expect(get("/repo_status/#{repo.owner_name}/#{repo.name}/builds.atom?token=#{token.token}", {}, {}).status).to eq(401)
          end
        end

        context 'and user does not have a RSS token' do
          before { user.tokens.rss.delete_all }

          it 'responds with 200' do
            expect(get("/repo_status/#{repo.owner_name}/#{repo.name}/builds.atom?token=#{token.token}", {}, {}).status).to eq(200)
          end
        end
      end
      
      context 'and token is a RSS one' do
        let(:token) { user.tokens.rss.first }

        it 'responds with 200' do
          expect(get("/repo_status/#{repo.owner_name}/#{repo.name}/builds.atom?token=#{token.token}", {}, {}).status).to eq(200)
        end
      end
    end
  end
end
