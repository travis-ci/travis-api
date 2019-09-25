# frozen_string_literal: true

module Travis
  class RemoteVCS
    class ConnectionError < StandardError
      def initialize
        super 'VCS connection error'
      end
    end
  end
end
