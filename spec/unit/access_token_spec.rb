require 'spec_helper'

describe Travis::Api::App::AccessToken do
  it 'errors out on wrong type of :expires_in argument' do
    expect {
      described_class.new(app_id: 1, user_id: 2, expires_in: 'foo')
    }.to raise_error(ArgumentError, 'expires_in must be of integer type')
  end

  it 'allows to skip expires_in' do
    expect {
      described_class.new(app_id: 1, user_id: 2, expires_in: nil)
    }.to_not raise_error(ArgumentError)
  end

  it 'does not reuse token if expires_in is set' do
    token     = described_class.new(app_id: 1, user_id: 2).tap(&:save)
    new_token = described_class.new(app_id: 1, user_id: 2, expires_in: 10)

    token.token.should_not == new_token.token
  end

  it 'expires the token after given period of time' do
    token = described_class.new(app_id: 1, user_id: 2, expires_in: 1).tap(&:save)

    described_class.find_by_token(token.token).should_not be_nil

    sleep 1.5

    described_class.find_by_token(token.token).should be_nil
  end
end
