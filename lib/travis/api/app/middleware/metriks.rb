require 'travis/api/app'

class Travis::Api::App
  class Middleware
    class Metriks < Middleware
      before do
        env['metriks.request.start'] = Time.now.utc
      end

      after do
        if response.status < 400
          time = Time.now.utc - env['metriks.request.start']
          pattern = headers['X-Pattern'].gsub(/[:\/]/, ".")
          metric = "api.request.endpoint.#{pattern}"
          Metriks.timer(metric).update(time)
          Metriks.meter("api.request.#{request.method}")
        end
        Metriks.meter("api.request.status.#{response.status.to_s[0]}")
      end
    end
  end
end
