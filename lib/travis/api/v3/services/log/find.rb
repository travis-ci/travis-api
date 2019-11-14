module Travis::API::V3
  class Services::Log::Find < Service
    params 'log.token'

    def run!
      log = query.find_by_job_id(params['job.id'])
      raise(NotFound, :log) unless access_control.visible? log
      
      meta_data = {
        "X-Robots-Tag": "noindex, noarchive, nosnippet"
      }
      result(log, meta_data)
    end
  end
end
