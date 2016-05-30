module Travis
  module Github
    module Services
      require 'travis/github/services/fetch_config'
      require 'travis/github/services/find_or_create_org'
      require 'travis/github/services/find_or_create_repo'
      require 'travis/github/services/find_or_create_user'
      require 'travis/github/services/set_hook'
      require 'travis/github/services/sync_user'

      class << self
        def register
          constants(false).each { |name| const_get(name) }
        end
      end
    end
  end
end
