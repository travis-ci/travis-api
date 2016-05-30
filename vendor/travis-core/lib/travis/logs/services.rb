module Travis
  module Logs
    module Services
      autoload :Aggregate, 'travis/logs/services/aggregate'
      autoload :Archive,   'travis/logs/services/archive'
      autoload :Receive,   'travis/logs/services/receive'

      class << self
        def register
          constants(false).each { |name| const_get(name) }
        end
      end
    end
  end
end


