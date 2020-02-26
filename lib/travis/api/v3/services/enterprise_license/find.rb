module Travis::API::V3
  class Services::EnterpriseLicense::Find < Service
    def run!
      if replicated_endpoint
        # We turn off verification because this is an internal IP and a self signed cert so it will always fail
        http_options = {url: replicated_endpoint, ssl: Travis.config.ssl.to_h.merge(verify: false)}.compact
        conn = Faraday.new(http_options) do |conn|
          conn.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
          conn.adapter Faraday.default_adapter
        end
        response = conn.get("license/v1/license")
        replicated_response = JSON.parse(response.body)
        license_id = replicated_response["license_id"]
        license_type = replicated_response["license_type"]
        seats = get_seats(replicated_response)
        expiration_time = replicated_response["expiration_time"]
        active_users = query.active_users

        result({
          license_id: license_id,
          license_type: license_type,
          seats: seats,
          active_users: active_users.count,
          expiration_time: expiration_time
        })
      else
        raise InsufficientAccess
      end
    end

    private

    def replicated_endpoint
      ENV['REPLICATED_INTEGRATIONAPI']
    end

    def get_seats(replicated_response)
      te_license = replicated_response["fields"].find { |te_fields| te_fields["field"] == "te_license" }
      yaml = YAML.load(te_license["value"])
      yaml["production"]["license"]["seats"]
      rescue Psych::SyntaxError, TypeError => e
        raise InsufficientAccess
    end
  end
end
