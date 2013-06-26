require 'travis/api/app'

class Travis::Api::App
  module Extensions
    module ExposePattern
      def route(verb, path, *)
        condition { headers('X-Endpoint' => settings.name.to_s, 'X-Pattern' => path.to_s) }
        super
      end
    end
  end
end
