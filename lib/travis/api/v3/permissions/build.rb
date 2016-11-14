require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Build < Permissions::Generic
    def cancel?
      cancelable?
    end

    def restart?
      restartable?
    end
  end
end
