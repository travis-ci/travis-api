module Travis::API::V3
  class Services::Build::Restart < Service

    def run
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless build = find(:build)
      access_control.permissions(build).restart!

      query.restart(access_control.user)
      accepted(build: build, state_change: :restart)
    end
  end
end
