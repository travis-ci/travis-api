require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::User < Permissions::Generic
    def import?
      write?
    end

    def sync?
      write?
    end
  end
end
