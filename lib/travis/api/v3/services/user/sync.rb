module Travis::API::V3
  class Services::User::Sync < Service

    def run!
      user = check_login_and_find(:user)
      access_control.permissions(user).sync!

      result query.sync(user)
    end
  end
end
