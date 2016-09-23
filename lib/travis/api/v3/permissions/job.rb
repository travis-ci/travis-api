require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Job < Permissions::Generic
    def cancel?
      read?
    end

    def restart?
      read?
    end

    def debug?
      write?
    end
  end
end
