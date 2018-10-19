require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Organization < Permissions::Generic
    def sync?
      write?
    end
  end
end
