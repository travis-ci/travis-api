module Travis::API::V3
  class Services::EnterpriseLicense::Find < Service
    def run!
      if replicated_license
        license_id = Travis.config.replicated.license_id
        license_type = Travis.config.replicated.license_type
        seats = get_seats()
        expiration_time = Travis.config.replicated.expiration_time
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

    def replicated_license
      Travis.config.replicated.license_id
    end

    def get_seats()
      yaml = YAML.load(Travis.config.replicated.license_custom)
      yaml["production"]["license"]["seats"]
    end
  end
end
