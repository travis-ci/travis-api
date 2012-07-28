require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Home < Endpoint
      set(:prefix, '/')

      # Landing point. Redirects web browsers to [API documentation](#/docs/).
      get '/' do
        redirect to('/docs/') if request.preferred_type('application/json', 'text/html') == 'text/html'
        { 'hello' => 'world' }
      end
    end
  end
end
