module Travis::API::V3
  class Services::EmailSubscription::Resubscribe < Service
    def run!
      return run_for_org if params.include?('organization.id')

      repository = check_login_and_find(:repository)
      return repo_migrated if migrated?(repository)

      query.resubscribe(access_control.user, repository)
      no_content
    end

    def run_for_org
      organization = check_login_and_find(:organization)

      query.resubscribe_organization(access_control.user, organization)
      no_content
    end
  end
end
