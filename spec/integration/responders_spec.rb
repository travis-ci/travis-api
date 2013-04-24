require 'spec_helper'

describe 'App' do
  before do
    FactoryGirl.create(:test, :number => '3.1', :queue => 'builds.common')

    responder = Class.new(Travis::Api::App::Responders::Base) do
      def apply?
        true
      end

      def apply
        resource[:extra] = 'moar!'

        resource
      end
    end

    add_endpoint '/foo' do
      get '/hash' do
        respond_with({ foo: 'bar' }, responders: [responder])
      end
    end
  end

  it '' do
    response = get '/foo/hash', {}, 'HTTP_ACCEPT' => 'application/json'
    JSON.parse(response.body).should == { 'foo' => 'bar', 'extra' => 'moar!' }
  end
end
