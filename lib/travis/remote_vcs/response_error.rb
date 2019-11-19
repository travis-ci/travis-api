# frozen_string_literal: true

module Travis
  class RemoteVCS
    class ResponseError < StandardError
      def initialize(message = 'VCS response error')
        super message
      end
    end
  end
end
