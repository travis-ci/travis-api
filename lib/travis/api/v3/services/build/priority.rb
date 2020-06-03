module Travis::API::V3
  class Services::Build::Priority < Service

    def run
      build = check_login_and_find(:build)
      query.priority
      accepted(build: build, priority: true)
    end
  end
end
