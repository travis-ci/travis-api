module Travis::API::V3
  class Models::LogPart < Travis::LogsModel
    belongs_to :log
  end
end
