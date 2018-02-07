require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Pusher < Endpoint
      PRIVATE_CHANNEL_FORMAT = /private-(?<type>\w+)-(?<id>\d+)\.?\w*/

      post '/auth', scope: :private do
        { channels: Hash[*authorized_channels.compact.flatten] }
      end

      private

        def authorized_channels
          params[:channels].map do |channel|
            [channel, authenticate(channel)] if signed_in? && authorized_for?(channel)
          end
        end

        def authorized_for?(channel)
          return false unless matches = PRIVATE_CHANNEL_FORMAT.match(channel)

          id = matches[:id].to_i
          case matches[:type]
          when 'user'
            current_user.id == id
          when 'repo'
            current_user.repository_ids.include?(id)
          when 'job'
            !!Travis.run_service(:find_job, current_user, id: id)
          else
            false
          end
        end

        def authenticate(channel)
          Travis.pusher[channel].authenticate(params[:socket_id])[:auth]
        end
    end
  end
end
