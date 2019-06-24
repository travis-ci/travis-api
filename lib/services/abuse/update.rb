# frozen_string_literal: true

module Services
  module Abuse
    class Update
      DEFAULT_ABUSE_REASON = 'Updated manually, through admin'

      def initialize(offender, offender_params, current_user)
        @offender = offender
        @current_user = current_user
        @offender_params = offender_params

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

          wanted = offender_params[key] == '1' ? true : false
          reason = offender_params['reason']

          if reason.present?
            update_abuse_and_reason(@offender, key, wanted, "#{DEFAULT_ABUSE_REASON}: #{reason}")
          else
            update_abuse_and_reason(@offender, key, wanted)
          end

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

      attr_reader :offender_params

      def update_abuse_and_reason(owner, key, value, reason = DEFAULT_ABUSE_REASON)
        case key
        when :not_fishy
          if !value
            ::Abuse.where(owner_id: owner.id, owner_type: owner.class.name, level: ::Abuse::LEVEL_FISHY).destroy_all
            ::Abuse.create!(level: ::Abuse::LEVEL_NOT_FISHY, reason: reason, owner_id: owner.id, owner_type: owner.class.name)
          else
            ::Abuse.where(owner_id: owner.id, owner_type: owner.class.name, level: ::Abuse::LEVEL_NOT_FISHY).destroy_all
          end
        when :offenders
          if value
            if offender_params['trusted']&.to_i.zero?
              ::Abuse.create!(level: ::Abuse::LEVEL_OFFENDER, reason: reason, owner_id: owner.id, owner_type: owner.class.name)

              Travis::DataStores.redis.srem('abuse:trusted', @offender.id)
            end
          else
            ::Abuse.where(level: ::Abuse::LEVEL_OFFENDER, owner_id: owner.id, owner_type: owner.class.name).destroy_all
          end
        when :trusted
          return unless value

          ::Abuse.where(owner_id: owner.id, owner_type: owner.class.name).destroy_all
          Travis::DataStores.redis.srem('abuse:offenders', @offender.id)
        end
      end

      def checked?(key)
        send(key) == '1'
      end

      def has?(key)
        Travis::DataStores.redis.sismember("abuse:#{key}", offender_key)
      end
    end
  end
end
