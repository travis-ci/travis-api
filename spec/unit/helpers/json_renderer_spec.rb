require 'spec_helper'
require 'json'

describe Travis::Api::App::Helpers::JsonRenderer do
  before do
    mock_app do
      helpers Travis::Api::App::Helpers::JsonRenderer
      get('/') { {'foo' => 'bar'} }
    end
  end

  it 'renders body as json' do
    get('/').should be_ok
    JSON.load(body).should == {'foo' => 'bar'}
  end
end
