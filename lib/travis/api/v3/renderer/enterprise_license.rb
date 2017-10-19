module Travis::API::V3
  module Renderer::EnterpriseLicense
    AVAILABLE_ATTRIBUTES = [ :seats, :active_users, :expiration_time ]
    extend self

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(license, **)
      {
        :seats => license[:seats],
        :active_users => license[:active_users],
        :expiration_time => license[:expiration_time]
      }
    end
  end
end