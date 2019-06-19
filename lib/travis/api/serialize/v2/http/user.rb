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
                data = {
                  'id'                 => user.id,
                  'name'               => user.name,
                  'login'              => user.login,
                  'email'              => user.email,
                  'gravatar_id'        => user.email ? Digest::MD5.hexdigest(user.email) : "",
                  'avatar_url'         => user.avatar_url,
                  'locale'             => user.locale,
                  'is_syncing'         => user.syncing?,
                  'synced_at'          => format_date(user.synced_at),
                  'correct_scopes'     => true,
                  # 'correct_scopes'     => Github::Oauth.correct_scopes?(user),
                  'created_at'         => format_date(user.created_at),
                  'first_logged_in_at' => format_date(user.first_logged_in_at),
                  'channels'           => channels,
                  'allow_migration'    => allow_migration,
                }

                if hmac_secret_key
                  data['secure_user_hash'] = secure_user_hash
                end

                data
              end

              def allow_migration
                Travis::Features.feature_active?(:allow_merge_globally) &&
                  Travis::Features.user_active?(:allow_migration, user)
              end

              def channels
                ["private-user-#{user.id}"]
              end

              def hmac_secret_key
                Travis.config.intercom && Travis.config.intercom.hmac_secret_key
              end

              def secure_user_hash
                OpenSSL::HMAC.hexdigest(
                  'sha256',
                  hmac_secret_key,
                  "#{user.id}"
                )
              end
          end
        end
      end
    end
  end
end
