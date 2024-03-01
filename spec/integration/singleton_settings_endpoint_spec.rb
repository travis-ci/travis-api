#require 'travis/api/app/endpoint/singleton_settings_endpoint'
describe Travis::Api::App::SettingsEndpoint do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 401) }

  before do
    model_class = Class.new(Repository::Settings::Model) do
      attribute :name, String
      attribute :secret, Travis::Settings::EncryptedValue

      validates :name, presence: true
      validates :secret, presence: true
    end
    Repository::Settings.class_eval do
      attribute :item, model_class
    end
    serializer_class = Class.new(Travis::Api::Serialize::ObjectSerializer) do
      attributes :name
    end
    Travis::Api::Serialize::V2::Http.const_set(:Item, serializer_class)

    add_settings_endpoint :item, singleton: true
  end

  after do
    Travis::Api::App::Endpoint.send :remove_const, :Item
    Travis::Api::Serialize::V2::Http.send :remove_const, :Item
  end

  describe 'with authenticated user' do
    let(:user)    { User.where(login: 'svenfuchs').first }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
    let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

    before { user.permissions.create!(:repository_id => repo.id, :admin => true, :push => true) }

    describe 'GET /item' do
      it 'returns an item' do
        settings = repo.settings
        item = settings.create(:item, name: 'an item', secret: 'TEH SECRET')
        settings.save

        response = get "/settings/item/#{repo.id}", {}, headers
        json = JSON.parse(response.body)
        expect(json['item']['name']).to eq('an item')
        expect(json['item']).not_to have_key('secret')
      end

      it 'returns 404 if item can\'t be found' do
        response = get "/settings/item/#{repo.id}", {}, headers
        json = JSON.parse(response.body)
        expect(json['error']).to eq("Could not find a requested setting")
      end
    end

    describe 'PATCH /item' do
      context 'when the repo is migrating' do
        before { repo.update(migration_status: "migrating") }

        it "responds with 403" do
          body = { item: { name: 'a name', secret: 'a secret' } }.to_json
          response = patch "/settings/item/#{repo.id}", body, headers
          expect(response.status).to eq(403)
        end
      end

      context 'when the repo is migrated' do
        before { repo.update(migration_status: "migrated") }

        it "responds with 403" do
          body = { item: { name: 'a name', secret: 'a secret' } }.to_json
          response = patch "/settings/item/#{repo.id}", body, headers
          expect(response.status).to eq(403)
        end
      end

      it 'should update an item' do
        settings = repo.settings
        item = settings.create(:item, name: 'an item', secret: 'TEH SECRET')
        settings.save

        body = { item: { name: 'a new name', secret: 'a new secret' } }.to_json
        response = patch "/settings/item/#{repo.id}", body, headers
        json = JSON.parse(response.body)
        expect(json['item']['name']).to eq('a new name')
        expect(json['item']).not_to have_key('secret')

        updated_item = repo.reload.settings.item
        expect(updated_item.name).to eq('a new name')
        expect(updated_item.secret.decrypt).to eq('a new secret')
      end

      it 'should create an item if it does not exist' do
        expect(repo.settings.item).to be_nil

        body = { item: { name: 'a name', secret: 'a secret' } }.to_json
        response = patch "/settings/item/#{repo.id}", body, headers
        json = JSON.parse(response.body)
        expect(json['item']['name']).to eq('a name')
        expect(json['item']).not_to have_key('secret')

        item = repo.reload.settings.item
        expect(item.name).to eq('a name')
        expect(item.secret.decrypt).to eq('a secret')
      end

      it 'returns an error message if item is invalid' do
        body = { item: { name: '' } }.to_json
        response = patch "/settings/item/#{repo.id}", body, headers
        expect(response.status).to eq(422)

        json = JSON.parse(response.body)
        expect(json['message']).to eq('Validation failed')
        expect(json['errors']).to eq([{
          'field' => 'name',
          'code' => 'missing_field'
        }, {
          'field' => 'secret',
          'code' => 'missing_field'
        }])

        expect(repo.reload.settings.item).to be_nil
      end
    end

    describe 'DELETE /item' do
      context 'when the repo is migrating' do
        before { repo.update(migration_status: "migrating") }

        it "responds with 403" do
          response = delete "/settings/item/#{repo.id}", {}, headers
          expect(response.status).to eq(403)
        end
      end

      context 'when the repo is migrated' do
        before { repo.update(migration_status: "migrated") }

        it "responds with 403" do
          response = delete "/settings/item/#{repo.id}", {}, headers
          expect(response.status).to eq(403)
        end
      end

      it 'should delete an item' do
        settings = repo.settings
        item = settings.create(:item, name: 'an item')
        settings.save

        response = delete "/settings/item/#{repo.id}", {}, headers
        json = JSON.parse(response.body)
        expect(json['item']['name']).to eq('an item')
        expect(json['item']).not_to have_key('secret')

        expect(repo.reload.settings.item).to be_nil
      end
    end
  end
end
