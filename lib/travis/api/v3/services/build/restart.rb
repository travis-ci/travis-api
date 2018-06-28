module Travis::API::V3
  class Services::Build::Restart < Service

    def run
      build = check_login_and_find(:build)
      access_control.permissions(build).restart!

      build.clear_debug_options!
      restart_status = query.restart(access_control.user)

      if restart_status == "abuse_detected"
        abuse_detected
      else
        accepted(build: build, state_change: :restart)
      end
    end
  end
end
