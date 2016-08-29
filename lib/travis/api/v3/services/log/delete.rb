module Travis::API::V3
  class Services::Log::Delete < Service
    def run!
      job = check_login_and_find(:job)
      check_access(job)
      query.delete(access_control.user, job)
      end
  end
end
