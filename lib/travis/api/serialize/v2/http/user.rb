require 'travis/api/serialize/formats'
require 'travis/github/oauth'
require 'travis/rollout'

module Travis
  module Api
    module Serialize
      module V2
        module Http
          class User
            class PusherChannels < Struct.new(:user)
              def channels
                repository_ids = []
                uids = user.repositories
                  .select(['repositories.id', 'repositories.owner_id', 'repositories.owner_type'])
                  .group_by { |r| "#{r.owner_id}-#{r.owner_type[0]}" }
                  .each do |uid, repositories|
                    # for each owner we need to add repositories to the list
                    # only if user channel is not enabled
                    rollout = Travis::Rollout.new('user-channel', redis: redis, uid: uid)
                    unless rollout.matches?
                      repository_ids.push(*repositories.map(&:id))
                    end
                  end

                ["user-#{user.id}"] + repository_ids.map { |id| "repo-#{id}" }
              end

              private

                def redis
                  Thread.current[:redis] ||= ::Redis.connect(url: Travis.config.redis.url)
                end
            end

            include Formats

            attr_reader :user, :options

            def initialize(user, options = {})
              @user = user
              @options = options
            end

            def data
              {
                'user' => user_data,
              }
            end

            private

              def user_data
                {
                  'id' => user.id,
                  'name' => user.name,
                  'login' => user.login,
                  'email' => user.email,
                  'gravatar_id' => user.email ? Digest::MD5.hexdigest(user.email) : "",
                  'avatar_url' => user.avatar_url,
                  'locale' => user.locale,
                  'is_syncing' => user.syncing?,
                  'synced_at' => format_date(user.synced_at),
                  'correct_scopes' => Github::Oauth.correct_scopes?(user),
                  'created_at' => format_date(user.created_at),
                  'channels' => channels
                }
              end

              def channels
                PusherChannels.new(user).channels
              end
          end
        end
      end
    end
  end
end
