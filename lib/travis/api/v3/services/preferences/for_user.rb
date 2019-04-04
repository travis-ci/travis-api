module Travis::API::V3
  class Services::Preferences::ForUser < Service
    def run!
      prefs = check_login_and_find(:preferences, access_control.user)
      result prefs
    end
  end
end
