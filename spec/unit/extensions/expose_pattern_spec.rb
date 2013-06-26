require 'spec_helper'

class Foo < Sinatra::Base
  register Travis::Api::App::Extensions::ExposePattern

  get '/:id' do
    "ok"
  end
end

describe Travis::Api::App::Extensions::ExposePattern do
  before { set_app(Foo) }

  example "it exposes the pattern" do
    get('/foo').should be_ok
    headers['X-Pattern'].should be == '/:id'
  end

  example "it exposes the app class" do
    get('/foo').should be_ok
    headers['X-Endpoint'].should be == 'Foo'
  end
end