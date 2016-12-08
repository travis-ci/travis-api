require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Cron < Permissions::Generic
    def delete?
      write?
    end

    def start?
      true
    end
  end
end
