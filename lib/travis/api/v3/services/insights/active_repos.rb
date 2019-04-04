require 'travis/api/v3/services/insights/insights_proxy'

module Travis::API::V3
  class Services::Insights::ActiveRepos < Services::Insights::InsightsProxy
    proxy endpoint: Travis.config.insights.endpoint + '/repos/active',
          auth_token: Travis.config.insights.auth_token

    params :owner_type, :owner_id
  end
end
