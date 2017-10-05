module Services
  module Abuse
    class Update
      def initialize(offender, offender_params, current_user)
        @offender = offender
        @current_user = current_user

        Offender::LISTS.each_key do |key|
          instance_variable_set("@#{key}", offender_params[key])
          self.class.send(:attr_reader, key)
        end
      end

      def offender_key
        "#{@offender.class.name}:#{@offender.id}"
      end

      def call
        Offender::LISTS.each_key do |key|
          next if checked?(key) == has?(key)

          if checked?(key)
            Travis::DataStores.redis.sadd("abuse:#{key}", offender_key)
            Services::AuditTrail::AddAbuseStatus.new(@current_user, offender_key, Offender::LISTS[key]).call
          else
            Travis::DataStores.redis.srem("abuse:#{key}", offender_key)
            Services::AuditTrail::RemoveAbuseStatus.new(@current_user, offender_key, Offender::LISTS[key]).call
          end
        end
      end

      private

      def checked?(key)
        send(key) == "1"
      end

      def has?(key)
        Travis::DataStores.redis.sismember("abuse:#{key}", offender_key)
      end
    end
  end
end
