require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module Services
      def service(key, user = current_user)
        const = Travis.services[key] || raise("no service registered for #{key}")
        const.new(user)
      end
    end
  end
end
