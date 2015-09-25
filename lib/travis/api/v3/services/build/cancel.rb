module Travis::API::V3
  class Services::Build::Cancel < Service

    def run
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless build = find(:build)
      access_control.permissions(build).cancel!

      payload = query.cancel(build)
      build
    end
  end
end
