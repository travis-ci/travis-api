module Travis::API::V3
  class Queries::EmailSubscription < Query
    def unsubscribe(user, repository)
      repository.email_unsubscribes.find_or_create_by!(user: user)
    end

    def resubscribe(user, repository)
      repository.email_unsubscribes.where(user: user).destroy_all
    end

    def unsubscribe_organization(user, organization)
      organization.repositories.each do |repo|
        repo.email_unsubscribes.find_or_create_by!(user: user) #if repo.permissions.find_by(user_id: user.id)
      end
    end

    def resubscribe_organization(user, organization)
      organization.repositories.each do |repo|
        repo.email_unsubscribes.where(user: user).destroy_all
      end
    end
  end
end
