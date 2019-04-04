module Travis::API::V3
  class Services::EmailSubscription::Unsubscribe < Service
    def run!
      repository = check_login_and_find(:repository)
      return repo_migrated if migrated?(repository)

      query.unsubscribe(access_control.user, repository)
      no_content
    end
  end
end
