module Travis::API::V3
  class Queries::Storage < Query
    params :user, :id,:value, prefix: :storage

    PERMITTED_OPTIONS = [:billing_wizard_state]

    def find
      Models::Storage.new(id: option_id).get if valid?
    end

    def update
      Models::Storage.new(id: option_id, value: value).create if valid?
    end

    def delete
      Models::Storage.new(id: option_id).delete if valid?
    end

    private
      def option_id
        "#{user}::storage::#{id}"
      end

      def valid?
        PERMITTED_OPTIONS.include? id.to_sym
      end


      def user
        params['user.id']
      end

      def id
        params['id']
      end

      def value
        params['value']
      end

      def redis
        Travis.redis
      end
  end
end
