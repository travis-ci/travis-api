require 'spec_helper'

describe Travis::Api::App::SettingsEndpoint do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

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
    serializer_class = Class.new(Travis::Api::Serializer) do
      attributes :id, :name
    end
    Travis::Api::Serialize::V2::Http.const_set(:Item, serializer_class)
    Travis::Api::Serialize::V2::Http.const_set(:Items, Travis::Api::ArraySerializer)

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
        json['item']['name'].should == 'an item'
        json['item']['id'].should == item.id
        json['item'].should_not have_key('secret')
      end

      it 'returns 404 if item can\'t be found' do
        response = get '/settings/items/123', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        json['error'].should == "Could not find a requested setting"
      end
    end

    describe 'GET /items' do
      it 'returns items list' do
        settings = repo.settings
        settings.items.create(name: 'an item', secret: 'TEH SECRET')
        settings.save

        response = get '/settings/items', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        json['items'].length.should == 1
        item = json['items'].first
        item['name'].should == 'an item'
        item['id'].should_not be_nil
        item.should_not have_key('secret')
      end
    end

    describe 'POST /items' do
      it 'creates a new item' do
        body = { item: { name: 'foo', secret: 'TEH SECRET' } }.to_json
        response = post "/settings/items?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        json['item']['name'].should == 'foo'
        json['item']['id'].should_not be_nil
        json['item'].should_not have_key('secret')

        item = repo.reload.settings.items.first
        item.id.should_not be_nil
        item.name.should == 'foo'
        item.secret.decrypt.should == 'TEH SECRET'
      end

      it 'returns error message if item is invalid' do
        response = post "/settings/items?repository_id=#{repo.id}", '{}', headers
        response.status.should == 422

        json = JSON.parse(response.body)
        json['message'].should == 'Validation failed'
        json['errors'].should == [{
          'field' => 'name',
          'code' => 'missing_field'
        }, {
          'field' => 'secret',
          'code'  => 'missing_field'
        }]

        repo.reload.settings.items.to_a.length.should == 0
      end
    end

    describe 'PATCH /items/:id' do
      it 'should update an item' do
        settings = repo.settings
        item = settings.items.create(name: 'an item', secret: 'TEH SECRET')
        settings.save

        body = { item: { name: 'a new name', secret: 'a new secret' } }.to_json
        response = patch "/settings/items/#{item.id}?repository_id=#{repo.id}", body, headers
        json = JSON.parse(response.body)
        json['item']['name'].should == 'a new name'
        json['item']['id'].should == item.id
        json['item'].should_not have_key('secret')

        updated_item = repo.reload.settings.items.find(item.id)
        updated_item.id.should == item.id
        updated_item.name.should == 'a new name'
        updated_item.secret.decrypt.should == 'a new secret'
      end

      it 'returns an error message if item is invalid' do
        settings = repo.settings
        item = settings.items.create(name: 'an item', secret: 'TEH SECRET')
        settings.save

        body = { item: { name: '' } }.to_json
        response = patch "/settings/items/#{item.id}?repository_id=#{repo.id}", body, headers
        response.status.should == 422

        json = JSON.parse(response.body)
        json['message'].should == 'Validation failed'
        json['errors'].should == [{
          'field' => 'name',
          'code' => 'missing_field'
        }]

        updated_item = repo.reload.settings.items.find(item.id)
        updated_item.id.should == item.id
        updated_item.name.should == 'an item'
        updated_item.secret.decrypt.should == 'TEH SECRET'
      end
    end

    describe 'DELETE /items/:id' do
      it 'should delete an item' do
        settings = repo.settings
        item = settings.items.create(name: 'an item', secret: 'TEH SECRET')
        settings.save

        params = { repository_id: repo.id }
        response = delete '/settings/items/' + item.id, params, headers
        json = JSON.parse(response.body)
        json['item']['name'].should == 'an item'
        json['item']['id'].should == item.id
        json['item'].should_not have_key('secret')

        repo.reload.settings.items.length.should == 0
      end

      it 'returns 404 if item can\'t be found' do
        response = delete '/settings/items/123', { repository_id: repo.id }, headers
        json = JSON.parse(response.body)
        json['error'].should == "Could not find a requested setting"
      end
    end
  end
end
