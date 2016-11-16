module Travis::API::V3
  class Services::Cron::Delete < Service
    def run!
      cron = check_login_and_find
      access_control.permissions(cron).delete!
      cron.destroy
      deleted
    end
  end
end
