module Travis
  module Requests
    module Services
      require 'travis/requests/services/receive'

      class << self
        def register
          constants(false).each { |name| const_get(name) }
        end
      end
    end
  end
end
