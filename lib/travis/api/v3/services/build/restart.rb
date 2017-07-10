module Travis::API::V3
  class Services::Build::Restart < Service

    def run
      build = check_login_and_find(:build)
      access_control.permissions(build).restart!

      build.clear_debug_options!
      if query.restart(access_control.user)
        accepted(build: build, state_change: :restart)
      end
    end
  end
end
