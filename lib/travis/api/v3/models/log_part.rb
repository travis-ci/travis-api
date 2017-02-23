module Travis::API::V3
  class Models::LogPart < Model
    establish_connection(Travis.config.logs_database)
    belongs_to :log
  end
end
