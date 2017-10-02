module Travis::API::V3
  module Renderer::EnterpriseLicense
    AVAILABLE_ATTRIBUTES = [ :seats ]
    extend self

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(license, **)
      {
        :seats => license[:seats]
      }
    end
  end
end