require 'sinatra/test_helpers'

module TestHelpers
  include Sinatra::TestHelpers

  def custom_endpoints
    @custom_endpoints ||= []
  end

  def add_settings_endpoint(name, options = {})
    if options[:singleton]
      Travis::Api::App::SingletonSettingsEndpoint.subclass(name)
    else
      Travis::Api::App::SettingsEndpoint.subclass(name)
    end
    set_app Travis::Api::App.new
  end

  def add_endpoint(prefix, &block)
    endpoint = Sinatra.new(Travis::Api::App::Endpoint, &block)
    endpoint.set(prefix: prefix)
    set_app Travis::Api::App.new
    custom_endpoints << endpoint
  end

  def parsed_body
    MultiJson.decode(body)
  end
end
