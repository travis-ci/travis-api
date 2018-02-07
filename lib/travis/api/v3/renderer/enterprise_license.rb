module Travis::API::V3
  module Renderer::EnterpriseLicense
    AVAILABLE_ATTRIBUTES = [ :license_id, :license_type, :seats, :active_users, :expiration_time ]
    extend self

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(license, **)
      {
        :license_id => license[:license_id],
        :license_type => license[:license_type],
        :seats => license[:seats],
        :active_users => license[:active_users],
        :expiration_time => license[:expiration_time]
      }
    end
  end
end