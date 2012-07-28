require 'spec_helper'

describe Travis::Api::App::Middleware::AccessToken do
  before do
    mock_app do
      use Travis::Api::App::Middleware::AccessToken
      get('/check_cors') { 'ok' }
    end
  end

  it 'sets associated scope properly'
  it 'lets through requests without a token'
  it 'reject requests with an invalide token'
  it 'rejects expired tokens'
  it 'checks that the token corresponds to Origin'
end