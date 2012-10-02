require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module MimeTypes
      def html?
        request.accept =~ %r(text/html)
      end

      def json?
        request.accept =~ %r(application/json)
      end

      def xml?
        request.accept =~ %r(application/xml)
      end

      def png?
        request.accept =~ %r(image/png)
      end
    end
  end
end

