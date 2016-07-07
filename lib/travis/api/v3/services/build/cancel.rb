module Travis::API::V3
  class Services::Build::Cancel < Service

    def run
      build = check_login_and_find(:build)
      access_control.permissions(build).cancel!

      query.cancel(access_control.user)
      accepted(build: build, state_change: :cancel)
    end
  end
end
