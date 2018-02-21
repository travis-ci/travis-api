module Travis::API::V3
  class Services::Log::Find < Service
    params 'log.token'

    def run!
      log = query.find_by_job_id(params['job.id'])
      raise(NotFound, :log) unless access_control.visible? log
      result log
    end
  end
end
