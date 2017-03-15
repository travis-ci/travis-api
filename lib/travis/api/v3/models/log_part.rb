module Travis::API::V3
  class Models::LogPart < LogsModel
    belongs_to :log
  end
end
