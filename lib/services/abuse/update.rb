module Services
  module Abuse
    class Update
      def initialize(login, offender_params, current_user)
        @login = login
        @current_user = current_user

        Offender::LISTS.each_key do |key|
          instance_variable_set("@#{key}", offender_params[key])
          self.class.send(:attr_reader, key)
        end
      end

      def call
        Offender::LISTS.each_key do |key|
          next if wanted?(key) == has?(key)

          if wanted?(key)
            Travis::DataStores.redis.sadd("abuse:#{key}", @login)
            Services::EventLogs::Add.new(@current_user, "marked #{@login} as #{Offender::LISTS[key]}").call
          else
            Travis::DataStores.redis.srem("abuse:#{key}", @login)
            Services::EventLogs::Add.new(@current_user, "removed #{@login} as #{Offender::LISTS[key]}").call
          end
        end
      end

      private

      def wanted?(key)
        send(key) == "1"
      end

      def has?(key)
        Travis::DataStores.redis.sismember("abuse:#{key}", @login)
      end
    end
  end
end
