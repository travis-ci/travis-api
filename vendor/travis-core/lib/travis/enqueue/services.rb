module Travis
  module Enqueue
    module Services
      require 'travis/enqueue/services/enqueue_jobs'

      class << self
        def register
          constants(false).each { |name| const_get(name) }
        end
      end
    end
  end
end

