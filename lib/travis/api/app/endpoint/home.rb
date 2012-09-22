require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Home < Endpoint
      set(:prefix, '/')

      # Landing point. Redirects web browsers to [API documentation](#/docs/).
      get '/' do
        pass if settings.disable_root_endpoint?
        redirect to('/docs/') if request.preferred_type('application/json', 'text/html') == 'text/html'
        { 'hello' => 'world' }
      end

      # Simple endpoints that redirects somewhere else, to make sure we don't
      # send a referrer.
      #
      # Parameters:
      #
      # * **to**: URI to redirect to after handshake.
      get '/redirect' do
        halt 400 unless params[:to] =~ %r{^https?://}
        redirect params[:to]
      end
    end
  end
end
