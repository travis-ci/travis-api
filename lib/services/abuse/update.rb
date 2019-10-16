module Services
  module Abuse
    class Update
      DEFAULT_ABUSE_REASON = 'Updated manually, through admin'

      def initialize(offender, params, current_user)
        @offender = offender
        @current_user = current_user
        @params = params
      end

      def offender_key
        "#{@offender.class.name}:#{@offender.id}"
      end

      def call
        reason = params[:reason]

        Offender::LISTS.each_key do |key|
          selected_abuse = key == :not_fishy ? not_fishy? : checked?(key)

          next if selected_abuse == has?(key)

          if reason.present?
            update_abuse_and_reason(@offender, key, selected_abuse, "#{DEFAULT_ABUSE_REASON}: #{reason}")
          else
            update_abuse_and_reason(@offender, key, selected_abuse)
          end

          if selected_abuse
            Travis::DataStores.redis.sadd("abuse:#{key}", offender_key)
            Services::AuditTrail::AddAbuseStatus.new(@current_user, offender_key, Offender::LISTS[key]).call
          else
            Travis::DataStores.redis.srem("abuse:#{key}", offender_key)
            Services::AuditTrail::RemoveAbuseStatus.new(@current_user, offender_key, Offender::LISTS[key]).call
          end
        end
      end

      private

      attr_reader :params

      def update_abuse_and_reason(owner, key, value, reason = DEFAULT_ABUSE_REASON)
        case key
        when :abuse_checks_enabled
          if value
            ::Abuse.where(owner_id: owner.id, owner_type: owner.class.name, level: ::Abuse::LEVEL_OFFENDER).destroy_all
          end
        when :not_fishy
          if value
            ::Abuse.where(owner_id: owner.id, owner_type: owner.class.name, level: ::Abuse::LEVEL_FISHY).destroy_all
            update_or_create_abuse(::Abuse::LEVEL_NOT_FISHY, owner, reason)
          else
            ::Abuse.where(owner_id: owner.id, owner_type: owner.class.name, level: ::Abuse::LEVEL_NOT_FISHY).destroy_all
            update_or_create_abuse(::Abuse::LEVEL_FISHY, owner, reason)
          end
        when :offenders
          if value
            update_or_create_abuse(::Abuse::LEVEL_OFFENDER, owner, reason) unless trusted?
          else
            ::Abuse.where(level: ::Abuse::LEVEL_OFFENDER, owner_id: owner.id, owner_type: owner.class.name).destroy_all
          end
        when :trusted
          return unless value

          ::Abuse.where(owner_id: owner.id, owner_type: owner.class.name).destroy_all
        end
      end

      def checked?(key)
        abuse_param == key.to_s
      end

      def not_fishy?
        params[:not_fishy] == '1'
      end

      def trusted?
        abuse_param == 'trusted'
      end

      def has?(key)
        Travis::DataStores.redis.sismember("abuse:#{key}", offender_key)
      end

      def update_or_create_abuse(level, owner, reason)
        ::Abuse.find_or_initialize_by(level: level,
                                      owner_id: owner.id,
                                      owner_type: owner.class.name).update(reason: reason)
      end

      def abuse_param
        params[:abuse]
      end
    end
  end
end
