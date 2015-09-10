module Travis::API::V3
  class Queries::Broadcasts < Query
    def for_repo(repository)
      Models::Broadcast.where(recipient_id: repository.id)
    end

    def for_user(user)
      Models::Broadcast.where(recipient_id: user.id)
    end
  end
end
