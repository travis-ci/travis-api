require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Cron < Permissions::Generic
    def delete?
      write? and Travis::Features.owner_active?(:cron, object.branch.repository.owner)
    end

    def start?
      Travis::Features.owner_active?(:cron, object.branch.repository.owner)
    end
  end
end
