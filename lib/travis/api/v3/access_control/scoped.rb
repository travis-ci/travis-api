require 'travis/api/v3/access_control/generic'

module Travis::API::V3
  class AccessControl::Scoped < AccessControl::Generic
    attr_accessor :unscoped, :anonymous, :owner_name, :name

    def initialize(scope, unscoped)
      @owner_name, @name = scope.split(?/.freeze, 2)
      @unscoped          = unscoped
      @anonymous         = AccessControl::Anonymous.new
    end

    protected

    def private_repository_visible?(repository)
      scope_repository(repository).visible?(repository)
    end

    def repository_writable?(repository)
      scope_repository(repository).writable?(repository)
    end

    def scope_repository(repository, method = caller_locations.first.base_label)
      return false if name and repository.name != name
      repository.owner_name == owner_name ? unscoped : anonymous
    end
  end
end
