require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module CurrentUser
      def current_user
        access_token.user if logged_in?
      end

      def access_token
        env['travis.access_token']
      end

      def logged_in?
        !!access_token
      end
    end
  end
end
