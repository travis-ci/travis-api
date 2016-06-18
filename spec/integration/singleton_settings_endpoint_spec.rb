require 'spec_helper'

describe Travis::Api::App::SettingsEndpoint do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

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
    serializer_class = Class.new(Travis::Api::Serializer) do
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
        json['item']['name'].should == 'an item'
        json['item'].should_not have_key('secret')
      end

      it 'returns 404 if item can\'t be found' do
        response = get "/settings/item/#{repo.id}", {}, headers
        json = JSON.parse(response.body)
        json['error'].should == "Could not find a requested setting"
      end
    end

    describe 'PATCH /item' do
      it 'should update an item' do
        settings = repo.settings
        item = settings.create(:item, name: 'an item', secret: 'TEH SECRET')
        settings.save

        body = { item: { name: 'a new name', secret: 'a new secret' } }.to_json
        response = patch "/settings/item/#{repo.id}", body, headers
        json = JSON.parse(response.body)
        json['item']['name'].should == 'a new name'
        json['item'].should_not have_key('secret')

        updated_item = repo.reload.settings.item
        updated_item.name.should == 'a new name'
        updated_item.secret.decrypt.should == 'a new secret'
      end

      it 'should create an item if it does not exist' do
        repo.settings.item.should be_nil

        body = { item: { name: 'a name', secret: 'a secret' } }.to_json
        response = patch "/settings/item/#{repo.id}", body, headers
        json = JSON.parse(response.body)
        json['item']['name'].should == 'a name'
        json['item'].should_not have_key('secret')

        item = repo.reload.settings.item
        item.name.should == 'a name'
        item.secret.decrypt.should == 'a secret'
      end

      it 'returns an error message if item is invalid' do
        body = { item: { name: '' } }.to_json
        response = patch "/settings/item/#{repo.id}", body, headers
        response.status.should == 422

        json = JSON.parse(response.body)
        json['message'].should == 'Validation failed'
        json['errors'].should == [{
          'field' => 'name',
          'code' => 'missing_field'
        }, {
          'field' => 'secret',
          'code' => 'missing_field'
        }]

        repo.reload.settings.item.should be_nil
      end
    end

    describe 'DELETE /item' do
      it 'should delete an item' do
        settings = repo.settings
        item = settings.create(:item, name: 'an item')
        settings.save

        response = delete "/settings/item/#{repo.id}", {}, headers
        json = JSON.parse(response.body)
        json['item']['name'].should == 'an item'
        json['item'].should_not have_key('secret')

        repo.reload.settings.item.should be_nil
      end
    end
  end
end
