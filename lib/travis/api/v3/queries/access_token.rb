module Travis::API::V3
  class Queries::AccessToken < Query
    def regenerate_token(user, token, app_id)
      Travis.redis.del("t:#{token}")
      Travis::Api::App::AccessToken.create(user: user, app_id: app_id, force: true).token
    end

    def remove_token(user, token, app_id)
      Travis.redis.del("t:#{token}")
      Travis.redis.del("r:#{user.id}:#{app_id}")
    end
  end
end
