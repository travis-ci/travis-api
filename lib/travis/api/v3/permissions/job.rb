require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Job < Permissions::Generic
    def cancel?
      write?
    end

    def restart?
      write?
    end

    def debug?
      write?
    end

    def delete_log?
      write?
    end
  end
end
