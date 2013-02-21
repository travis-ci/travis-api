require 'spec_helper'

describe 'App' do
  before do
    add_endpoint '/foo' do
      get '/' do
        respond_with foo: 'bar'
      end
    end
  end

  it 'uses version from current accept header' do
    Travis::Api.expects(:builder).with { |r, options| options[:version] == 'v1' }

    Travis::Api::App::Responders::Json.any_instance.stubs(:apply?).
        returns(false).then.returns(true)

    response = get '/foo', {}, 'HTTP_ACCEPT' => 'application/json; version=2, application/json; version=1'
    response.content_type.should == 'application/json;charset=utf-8'
  end

  it 'uses v1 by default' do
    Travis::Api.expects(:builder).with { |r, options| options[:version] == 'v1' }
    get '/foo', {}, 'HTTP_ACCEPT' => 'application/json'
  end
end
