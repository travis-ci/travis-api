require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Build < Permissions::Generic
    def cancel?
      read?
    end

    def restart?
      read?
    end
  end
end
