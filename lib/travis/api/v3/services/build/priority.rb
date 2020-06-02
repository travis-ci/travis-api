module Travis::API::V3
  class Services::Build::Priority < Service

    def run
      build = check_login_and_find(:build)
      query.priority(access_control.user)
      accepted(build: build, priority: true)
    end
  end
end
