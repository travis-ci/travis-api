module Travis::API::V3
  class Services::Cron::Delete < Service
    #params :id

    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?

      access_control.permissions(cron).delete!
      find.destroy
    end
  end
end
