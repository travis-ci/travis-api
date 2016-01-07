require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Lint < Permissions::Generic
    def lint?
      write?
    end
  end
end
