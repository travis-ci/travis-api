module Travis::API::V3
  class Services::Settings::Update < Service
    params :builds_only_with_travis_yml, :build_pushes, :build_pull_requests, :maximum_number_of_builds, prefix: :settings

    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound unless repository = find(:repository)
      query.update(repository)
    end
  end
end
