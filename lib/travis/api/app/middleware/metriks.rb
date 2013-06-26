require 'travis/api/app'
require 'metriks'

class Travis::Api::App
  class Middleware
    class Metriks < Middleware
      include Helpers::Accept

      before do
        env['metriks.request.start'] = Time.now.utc
      end

      after do
        if response.status < 400
          time = Time.now.utc - env['metriks.request.start']
          if headers['X-Pattern'].present? and headers['X-Endpoint'].present?
            name = "#{(headers['X-Endpoint'].split("::", 5).last.gsub(/::/, ".")).downcase}#{headers['X-Pattern'].gsub(/[\/]/, '.').gsub(/[:\?\*]/, "_")}"
            metric = "api.request.endpoint.#{name}"
            ::Metriks.timer(metric).update(time)
            ::Metriks.timer('api.requests').update(time)
          end
          ::Metriks.meter("api.request.#{request.request_method.downcase}").mark
        end
        ::Metriks.meter("api.request.status.#{response.status.to_s[0]}").mark
        ::Metriks.meter("api.request.version.#{accept_version}").mark
      end
    end
  end
end
