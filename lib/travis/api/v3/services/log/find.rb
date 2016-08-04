module Travis::API::V3
  class Services::Log::Find < Service
    def run!
      job = find(:job)
      query.find(job)
    end
  end
end
