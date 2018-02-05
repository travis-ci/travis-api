require 'travis/api/serialize/formats'
require 'travis/github/oauth'

module Travis
  module Api
    module Serialize
      module V2
        module Http
          class User
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
                  'gravatar_id' => user.email ? Digest::MD5.hexdigest(user.email.downcase) : "",
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
                ["private-user-#{user.id}"]
              end
          end
        end
      end
    end
  end
end
