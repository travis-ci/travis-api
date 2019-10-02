# frozen_string_literal: true

module Travis
  class RemoteVCS
    class ResponseError < StandardError
      def initialize
        super 'VCS response error'
      end
    end
  end
end
