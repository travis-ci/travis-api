module Travis::API::V3
  class Services::Queues::Stats < Service
    result_type :jobs_stats

    def run!
      raise LoginRequired unless access_control.full_access?
      result query(:jobs).stats_by_queue(params['queue.name'])
    end
  end
end
