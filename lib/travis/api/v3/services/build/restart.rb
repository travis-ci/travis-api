module Travis::API::V3
  class Services::Build::Restart < Service

    def run
      build = check_login_and_find(:build)
      return not_found if build.owner.ro_mode?
      return repo_migrated if migrated?(build.repository)

      access_control.permissions(build).restart!
      build.clear_debug_options!

      result = query.restart(access_control.user)

      if result.success?
        accepted(build: build, state_change: :restart)
      elsif result.error == Travis::Enqueue::Services::RestartModel::ABUSE_DETECTED
        abuse_detected
      else
        insufficient_balance
      end
    end
  end
end
