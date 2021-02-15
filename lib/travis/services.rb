module Travis
  module Services
    module Registry
      def add(key, const = nil)
        if key.is_a?(Hash)
          key.each { |key, const| add(key, const) }
        else
          services[key.to_sym] = const
        end
      end

      def [](key)
        services[key.to_sym] || raise("can not use unregistered service #{key}. known services are: #{services.keys.inspect}")
      end

      private

        def services
          @services ||= {}
        end
    end

    extend Registry

    class << self
      def register
        constants(false).each { |name| const_get(name) }
      end
    end
  end
end

require 'travis/services/helpers'

module Travis
  extend Services::Helpers
end

require 'travis/services/base'
require 'travis/services/delete_caches'
require 'travis/services/find_admin'
require 'travis/services/find_branch'
require 'travis/services/find_branches'
require 'travis/services/find_build'
require 'travis/services/find_build_backups'
require 'travis/services/find_builds'
require 'travis/services/find_caches'
require 'travis/services/find_hooks'
require 'travis/services/find_job'
require 'travis/services/find_jobs'
require 'travis/services/find_log'
require 'travis/services/find_repo'
require 'travis/services/find_repos'
require 'travis/services/find_repo_key'
require 'travis/services/find_requests'
require 'travis/services/find_request'
require 'travis/services/find_repo_settings'
require 'travis/services/find_user_accounts'
require 'travis/services/find_user_broadcasts'
require 'travis/services/find_user_permissions'
require 'travis/services/next_build_number'
require 'travis/services/regenerate_repo_key'
require 'travis/services/remove_log'
require 'travis/services/sync_user'
require 'travis/services/update_hook'
require 'travis/services/update_job'
require 'travis/services/update_user'
