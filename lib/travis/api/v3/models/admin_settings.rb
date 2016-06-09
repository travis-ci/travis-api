module Travis::API::V3
  class Models::AdminSettings < Travis::Settings::Model
    attribute :api_builds_rate_limit, Integer
  end
end
