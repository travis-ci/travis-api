describe Travis::Api::App::SettingsEndpoint do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 401) }

  before do
    model_class = Class.new(Repository::Settings::Model) do
      attribute :id, String
      attribute :name, String
      attribute :secret, Travis::Settings::EncryptedValue

      validates :name, presence: true
      validates :secret, presence: true
    end
    collection_class = Class.new(Repository::Settings::Collection) do
      model model_class
    end
    Repository::Settings.class_eval do
      attribute :items, collection_class
    end
    serializer_class = Class.new(Travis::Api::Serialize::ObjectSerializer) do
      attributes :id, :name
    end
    Travis::Api::Serialize::V2::Http.const_set(:Item, serializer_class)
    Travis::Api::Serialize::V2::Http.const_set(:Items, Travis::Api::Serialize::ArraySerializer)

    add_settings_endpoint :items
  end

  after do
    Travis::Api::App::Endpoint.send :remove_const, :Items
    Travis::Api::Serialize::V2::Http.send :remove_const, :Items
    Travis::Api::Serialize::V2::Http.send :remove_const, :Item
  end

  describe 'with authenticated user' do
    let(:user)    { User.where(login: 'svenfuchs').first }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
    let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

    before { user.permissions.create!(:repository_id => repo.id, :admin => true, :push => true) }

    describe 'GET /items/:id' do
      it 'returns an item' do
        settings = repo.settings
        item = settings.items.create(name: 'an item', secret: 'TEH SECRET')
        settings.save

        response = get '/settings/items/' + item.id, { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        expect(json['item']['name']).to eq('an item')
        expect(json['item']['id']).to eq(item.id)
        expect(json['item']).not_to have_key('secret')
      end

      it 'returns 404 if item can\'t be found' do
        response = get '/settings/items/123', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        expect(json['error']).to eq("Could not find a requested setting")
      end
    end

    describe 'GET /items' do
      it 'returns items list' do
        settings = repo.settings
        settings.items.create(name: 'an item', secret: 'TEH SECRET')
        settings.save

        response = get '/settings/items', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        expect(json['items'].length).to eq(1)
        item = json['items'].first
        expect(item['name']).to eq('an item')
        expect(item['id']).not_to be_nil
        expect(item).not_to have_key('secret')
      end
    end

    describe 'POST /items' do
      context 'when the repo is migrating' do
        before { repo.update(migration_status: "migrating") }

        it "responds with 403" do
          body = { item: { name: 'foo', secret: 'TEH SECRET' } }.to_json
          response = post "/settings/items?repository_id=#{repo.id}", body, headers
          expect(response.status).to eq(403)
        end
      end

      context 'when the repo is migrated' do
        before { repo.update(migration_status: "migrated") }

        it "responds with 403" do
          body = { item: { name: 'foo', secret: 'TEH SECRET' } }.to_json
          response = post "/settings/items?repository_id=#{repo.id}", body, headers
          expect(response.status).to eq(403)
        end
      end

      it 'creates a new item' do
        body = { item: { name: 'foo', secret: 'TEH SECRET' } }.to_json
        response = post "/settings/items?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        expect(json['item']['name']).to eq('foo')
        expect(json['item']['id']).not_to be_nil
        expect(json['item']).not_to have_key('secret')

        item = repo.reload.settings.items.first
        expect(item.id).not_to be_nil
        expect(item.name).to eq('foo')
        expect(item.secret.decrypt).to eq('TEH SECRET')
      end

      it 'returns error message if item is invalid' do
        response = post "/settings/items?repository_id=#{repo.id}", '{}', headers
        expect(response.status).to eq(422)

        json = JSON.parse(response.body)
        expect(json['message']).to eq('Validation failed')
        expect(json['errors']).to eq([{
          'field' => 'name',
          'code' => 'missing_field'
        }, {
          'field' => 'secret',
          'code'  => 'missing_field'
        }])

        expect(repo.reload.settings.items.to_a.length).to eq(0)
      end
    end

    describe 'PATCH /items/:id' do
      context 'when the repo is migrating' do
        before { repo.update(migration_status: "migrating") }

        it "responds with 403" do
          settings = repo.settings
          item = settings.items.create(name: 'an item', secret: 'TEH SECRET')
          settings.save

          body = { item: { name: 'a new name', secret: 'a new secret' } }.to_json
          response = patch "/settings/items/#{item.id}?repository_id=#{repo.id}", body, headers
          expect(response.status).to eq(403)

        end
      end

      context 'when the repo is migrated' do
        before { repo.update(migration_status: "migrated") }

        it "responds with 403" do
          settings = repo.settings
          item = settings.items.create(name: 'an item', secret: 'TEH SECRET')
          settings.save

          body = { item: { name: 'a new name', secret: 'a new secret' } }.to_json
          response = patch "/settings/items/#{item.id}?repository_id=#{repo.id}", body, headers
          expect(response.status).to eq(403)
        end
      end

      it 'should update an item' do
        settings = repo.settings
        item = settings.items.create(name: 'an item', secret: 'TEH SECRET')
        settings.save

        body = { item: { name: 'a new name', secret: 'a new secret' } }.to_json
        response = patch "/settings/items/#{item.id}?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        expect(json['item']['name']).to eq('a new name')
        expect(json['item']['id']).to eq(item.id)
        expect(json['item']).not_to have_key('secret')

        updated_item = repo.reload.settings.items.find(item.id)
        expect(updated_item.id).to eq(item.id)
        expect(updated_item.name).to eq('a new name')
        expect(updated_item.secret.decrypt).to eq('a new secret')
      end

      it 'returns an error message if item is invalid' do
        settings = repo.settings
        item = settings.items.create(name: 'an item', secret: 'TEH SECRET')
        settings.save

        body = { item: { name: '' } }.to_json
        response = patch "/settings/items/#{item.id}?repository_id=#{repo.id}", body, headers
        expect(response.status).to eq(422)

        json = JSON.parse(response.body)
        expect(json['message']).to eq('Validation failed')
        expect(json['errors']).to eq([{
          'field' => 'name',
          'code' => 'missing_field'
        }])

        updated_item = repo.reload.settings.items.find(item.id)
        expect(updated_item.id).to eq(item.id)
        expect(updated_item.name).to eq('an item')
        expect(updated_item.secret.decrypt).to eq('TEH SECRET')
      end
    end

    describe 'DELETE /items/:id' do
      context 'when the repo is migrating' do
        before { repo.update(migration_status: "migrating") }

        it "responds with 403" do
          settings = repo.settings
          item = settings.items.create(name: 'an item', secret: 'TEH SECRET')
          settings.save

          params = { repository_id: repo.id }
          response = delete '/settings/items/' + item.id, params, headers

          expect(response.status).to eq(403)

        end
      end

      context 'when the repo is migrated' do
        before { repo.update(migration_status: "migrated") }

        it "responds with 403" do
          settings = repo.settings
          item = settings.items.create(name: 'an item', secret: 'TEH SECRET')
          settings.save

          params = { repository_id: repo.id }
          response = delete '/settings/items/' + item.id, params, headers

          expect(response.status).to eq(403)
        end
      end


      it 'should delete an item' do
        settings = repo.settings
        item = settings.items.create(name: 'an item', secret: 'TEH SECRET')
        settings.save

        params = { repository_id: repo.id }
        response = delete '/settings/items/' + item.id, params, headers
        json = JSON.parse(response.body)
        expect(json['item']['name']).to eq('an item')
        expect(json['item']['id']).to eq(item.id)
        expect(json['item']).not_to have_key('secret')

        expect(repo.reload.settings.items.length).to eq(0)
      end

      it 'returns 404 if item can\'t be found' do
        response = delete '/settings/items/123', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        expect(json['error']).to eq("Could not find a requested setting")
      end
    end
  end
end
