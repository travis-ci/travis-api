class Travis::Api::App
  class Middleware
    module Appsignal
      def self.new(app) app end
    end
  end
end
