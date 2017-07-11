module Travis::API::V3
  class Services::Log::Find < Service
    def run!
      job = check_login_and_find(:job)
      result query.find(job)
    end
  end
end
