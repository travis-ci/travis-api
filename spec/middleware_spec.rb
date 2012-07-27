require 'spec_helper'

describe Travis::Api::App::Middleware do
  class MyMiddleware < Travis::Api::App::Middleware
    get('/my_middleware') { 'ok' }
  end

  it 'sets up middleware automatically' do
    get('/my_middleware').should be_ok
    body.should == "ok"
  end
end
