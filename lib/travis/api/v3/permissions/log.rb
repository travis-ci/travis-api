require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Log < Permissions::Generic
    def cancel?
      cancelable?
    end

    def restart?
      restartable?
    end

    def debug?
      write?
    end

    def delete_log?
      write?
    end
  end
end
