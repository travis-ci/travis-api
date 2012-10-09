require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module Flash
      def flash
        @flash ||= []
      end
    end
  end
end
