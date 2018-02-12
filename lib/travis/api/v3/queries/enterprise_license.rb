require 'redis'

module Travis::API::V3
  class Queries::EnterpriseLicense < Query
    def active_users
      Travis::API::V3::Models::User.where('github_oauth_token IS NOT NULL AND suspended IS NULL')
    end
  end
end