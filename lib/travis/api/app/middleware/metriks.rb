require 'travis/api/app'
require 'metriks'

class Travis::Api::App
  class Middleware
    class Metriks < Middleware
      include Helpers::Accept

      before do
        env['metriks.request.start'] ||= Time.now.utc
      end

      after do
        if queue_start = time(env['HTTP_X_QUEUE_START']) || time(env['HTTP_X_REQUEST_START'])
          time = env['metriks.request.start'] - queue_start
          ::Metriks.timer('api.request_queue').update(time)
        end

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

      def time(value)
        value = value.to_f
        start = env['metriks.request.start'].to_f
        value /= 1000 while value > start
        Time.at(value) if value > 946684800
      end
    end
  end
end
