require 'travis/api/v3/access_control/generic'

module Travis::API::V3
  class AccessControl::User < AccessControl::Generic
    attr_reader :user, :permissions

    def initialize(user)
      @user        = user
      @permissions = user.permissions.where(user_id: user.id)
      super()
    end

    protected

    def private_repository_visible?(repository)
      permissions?(:pull, repository)
    end

    def permission?(type, id)
      id = id.id if id.is_a? ::Repository
      permissions.where(type => trye, :repository_id => id).any?
    end
  end
end
