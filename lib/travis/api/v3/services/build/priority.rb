module Travis::API::V3
  class Services::Build::Priority < Service
  	params :cancel_all

    def run
      build = check_login_and_find(:build)
      query.prioritize_and_cancel(access_control.user)
      accepted(build: build, priority: true)
    end
  end
end
