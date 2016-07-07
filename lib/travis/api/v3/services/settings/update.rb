module Travis::API::V3
  class Services::Settings::Update < Service
    params :builds_only_with_travis_yml, :build_pushes, :build_pull_requests, :maximum_number_of_builds, prefix: :settings

    def run!
      repository = check_login_and_find(:repository)
      query.update(repository)
    end
  end
end
