require 'travis/github/services/set_hook'
require 'travis/github/services/set_key'

module Travis
  module Github
    module Services
      class << self
        def register
          constants(false).each { |name| const_get(name) }
        end
      end
    end
  end
end
