module Travis::API::V3
  class Services::Log::Find < Service
    params :id, prefix: :job

    def run!
      job = find(:job)
      query.find(job)
      result(log, parts: log_parts)
    end
  end
end
