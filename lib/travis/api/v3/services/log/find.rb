module Travis::API::V3
  class Services::Log::Find < Service
    params :id, prefix: :job

    def run!
      job = find(:job)
      query.find(job)
    end
  end
end
