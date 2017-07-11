module Travis::API::V3
  class Services::Log::Delete < Service
    def run!
      job = check_login_and_find(:job)
      access_control.permissions(job).delete_log!
      result query.delete(access_control.user, job)
    end
  end
end
