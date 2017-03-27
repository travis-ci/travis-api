require 'travis/api/app'

class Travis::Api::App
  class Middleware
    class ErrorResponse < Middleware
      configure do
        disable  :raise_errors
      end
    end
  end
end
