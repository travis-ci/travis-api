require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Uptime < Endpoint
      get '/', scope: :hidden do
        begin
          ActiveRecord::Base.connection.execute('select 1')
          [200, "OK"]
        rescue Exception => e
          return [500, "Error: #{e.message}"]
        end
      end
    end
  end
end
