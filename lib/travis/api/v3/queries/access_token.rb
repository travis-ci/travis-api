module Travis::API::V3
  class Queries::AccessToken < Query
    def regenerate_token(user, token, app_id, expires_in: nil)
      Travis.redis.del("t:#{token}")
      new_token = Travis::Api::App::AccessToken.create(user: user, app_id: app_id, expires_in:, force: true).token
      Travis::API::V3::Models::Audit.create!(
        owner: user,
        change_source: 'travis-api',
        source: user,
        source_changes: {
          action: 'regenerate_token',
          old_api_token: token,
          new_api_token: new_token,
        }
      )
      new_token
    end

    def remove_token(user, token, app_id)
      Travis.redis.del("t:#{token}")
      Travis.redis.del("r:#{user.id}:#{app_id}")
    end
  end
end
