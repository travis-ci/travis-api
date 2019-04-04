module Travis::API::V3
  class Queries::EmailSubscription < Query
    def unsubscribe(user, repository)
      repository.email_unsubscribes.find_or_create_by!(user: user)
    end

    def resubscribe(user, repository)
      repository.email_unsubscribes.where(user: user).destroy_all
    end
  end
end
