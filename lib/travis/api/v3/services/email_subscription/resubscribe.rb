module Travis::API::V3
  class Services::EmailSubscription::Resubscribe < Service
    def run!
      repository = check_login_and_find(:repository)
      return repo_migrated if migrated?(repository)

      query.resubscribe(access_control.user, repository)
      no_content
    end
  end
end
