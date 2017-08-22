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
      starable?
    end

    def unstar?
      starable?
    end

    def create_cron?
      write?
    end

    def create_env_var?
      write?
    end

    def create_key_pair?
      write?
    end

    def delete_key_pair?
      write?
    end

    def create_request?
      write?
    end

    def admin?
      access_control.adminable? object
    end

    def is_collaborator?
      read?
    end
  end
end
