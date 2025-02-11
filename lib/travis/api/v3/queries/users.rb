module Travis::API::V3
  class Queries::Users < Query
    params :user_ids

    def suspend(value)
      Models::User.where('id in (?)' , ids).update!(suspended: value, suspended_at: value ? Time.now.utc : nil)
      Models::BulkChangeResult.new(
        changed: ids - unknown_ids,
        skipped: unknown_ids
      )
    end

    def unknown_ids
      @_unknown_ids ||= ids - User.where('id in (?)', ids).all.map(&:id)
    end

    def ids
      @_ids ||= params['user_ids']
    end
  end
end
