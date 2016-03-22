module Travis::API::V3
  class Services::Cron::Delete < Service
    #params :id

    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      cron = find
      access_control.permissions(cron).delete!
      cron.destroy
    end
  end
end
