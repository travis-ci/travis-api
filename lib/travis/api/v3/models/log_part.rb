module Travis::API::V3
  class Models::LogPart < Model
    if Travis.config.logs_api.enabled?
      establish_connection(Travis.config.logs_readonly_database)
    else
      establish_connection(Travis.config.logs_database)
    end
    belongs_to :log
  end
end
