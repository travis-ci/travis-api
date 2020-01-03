module Travis::API::V3
  class Services::EnterpriseLicense::Find < Service
    def run!
      if replicated_endpoint
        license_id = ENV['REPLICATED_LICENSELICENSEID']
        license_type = ENV['REPLICATED_LICENSECHANNELNAME']
        seats = get_seats()
        expiration_time = ENV['REPLICATED_LICENSEEXPIRATIONDATE']
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
      ENV['REPLICATED_LICENSELICENSEID']
    end

    def get_seats()
      yaml = YAML.load(ENV['REPLICATED_CUSTOMLICENSE'])
      yaml["production"]["license"]["seats"]
    end
  end
end
