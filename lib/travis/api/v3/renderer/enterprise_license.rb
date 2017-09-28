module Travis::API::V3
  module Renderer::EnterpriseLicense
    AVAILABLE_ATTRIBUTES = [ :foo ]
    extend self

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(license, **)
      {
        :foo => "bar"
      }
    end
  end
end