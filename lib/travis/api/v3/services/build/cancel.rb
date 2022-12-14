module Travis::API::V3
  class Services::Build::Cancel < Service

    def run
      build = check_login_and_find(:build)
      return not_found if build.owner.ro_mode?

      access_control.permissions(build).cancel!

      query.cancel(access_control.user, build.id)
      accepted(build: build, state_change: :cancel)
    end
  end
end
