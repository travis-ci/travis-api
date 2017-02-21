require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Repository < Permissions::Generic
    def activate?
      write?
    end

    def deactivate?
      write?
    end

    def star?
      write?
    end

    def unstar?
      write?
    end

    def create_request?
      write?
    end

    def create_cron?
      write?
    end

    def change_env_vars?
      write?
    end

    def change_key?
      write?
    end

    def admin?
      access_control.adminable? object
    end
  end
end
