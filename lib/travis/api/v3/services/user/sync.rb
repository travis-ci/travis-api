module Travis::API::V3
  class Services::User::Sync < Service

    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless user = find(:user)
      access_control.permissions(user).sync!

      query.sync(user)
    end
  end
end
