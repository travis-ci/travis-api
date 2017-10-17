module Travis::API::V3
  module Renderer::EnterpriseLicense
    AVAILABLE_ATTRIBUTES = [ :seats, :active_users ]
    extend self

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(license, **)
      {
        :seats => license[:seats],
        :active_users => license[:active_users]
      }
    end
  end
end