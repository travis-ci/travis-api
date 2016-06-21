require 'travis/github/services/set_hook'

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
