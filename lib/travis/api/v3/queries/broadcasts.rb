module Travis::API::V3
  class Queries::Broadcasts < Query
    def for_user(user)
      query = %(
        recipient_type IS NULL OR
        recipient_type = ? AND recipient_id IN(?) OR
        recipient_type = ? AND recipient_id = ? OR
        recipient_type = ? AND recipient_id IN (?)
      )
      Models::Broadcast.where(query, 'Organization', user.organization_ids, 'User', user.id, 'Repository', user.repository_ids)
    end
  end
end
