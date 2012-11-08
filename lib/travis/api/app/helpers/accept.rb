require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module Accept
      HEADER_FORMAT   = /vnd\.travis-ci\.(\d+)\+(\w+)/
      DEFAULT_VERSION = 'v1'
      DEFAULT_FORMAT  = 'json'

      def accept_version
        @accept_version ||= request.accept.join =~ HEADER_FORMAT && "v#{$1}" || DEFAULT_VERSION
      end

      def accept_format
        @accept_format ||= request.accept.join =~ HEADER_FORMAT && $2 || DEFAULT_FORMAT
      end
    end
  end
end
