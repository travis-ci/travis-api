require 'spec_helper'

describe Travis::Api::App::Endpoint::Authorization::UserManager do
  let(:manager) { described_class.new(data, 'abc123') }

  describe '#info' do
    let(:data) {
      {
        name: 'Piotr Sarnacki', login: 'drogus', gravatar_id: '123', id: 456, foo: 'bar'
      }.stringify_keys
    }

    it 'gets data from github payload' do
      manager.info.should == {
        name: 'Piotr Sarnacki', login: 'drogus', gravatar_id: '123', github_id: 456
      }.stringify_keys
    end

    it 'allows to overwrite existing keys' do
      manager.info({login: 'piotr.sarnacki', bar: 'baz'}.stringify_keys).should == {
        name: 'Piotr Sarnacki', login: 'piotr.sarnacki', gravatar_id: '123',
        github_id: 456, bar: 'baz'
      }.stringify_keys
    end
  end

  describe '#fetch' do
   let(:data) {
      { login: 'drogus', id: 456 }.stringify_keys
    }

    it 'drops the token when drop_token is set to true' do
      user = stub('user', login: 'drogus', github_id: 456)
      User.expects(:find_by_github_id).with(456).returns(user)

      manager = described_class.new(data, 'abc123', true)

      attributes = { login: 'drogus', github_id: 456 }.stringify_keys

      user.expects(:update_attributes).with(attributes)

      manager.fetch.should == user
    end

    context 'with existing user' do
      it 'updates user data' do
        user = stub('user', login: 'drogus', github_id: 456)
        User.expects(:find_by_github_id).with(456).returns(user)
        attributes = { login: 'drogus', github_id: 456, github_oauth_token: 'abc123' }.stringify_keys
        user.expects(:update_attributes).with(attributes)

        manager.fetch.should == user
      end
    end

    context 'without existing user' do
      it 'creates new user' do
        user = stub('user', login: 'drogus', github_id: 456)
        User.expects(:find_by_github_id).with(456).returns(nil)
        attributes = { login: 'drogus', github_id: 456, github_oauth_token: 'abc123' }.stringify_keys
        User.expects(:create!).with(attributes).returns(user)

        manager.fetch.should == user
      end
    end
  end
end
