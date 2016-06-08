module Travis::API::V3
  module Renderer::Settings
    extend self

    AVAILABLE_ATTRIBUTES = [:settings]

    def available_attributes
      AVAILABLE_ATTRIBUTES 
    end

    def render(settings, **)
      response = { '@type' => 'settings'.freeze }
      response.merge(settings.to_h)
    end
  end
end
