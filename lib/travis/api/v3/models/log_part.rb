module Travis::API::V3
  class Models::LogPart < Model
    establish_connection 'logs_database'
    belongs_to :log

    def replicate_log_parts_object(value)
      # use this method to turn archived s3 log into something that looks
      # like the log_parts object the logs db log_part query send to the router/renderer

    end
  end
end
