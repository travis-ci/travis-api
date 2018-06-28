require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Pusher < Endpoint
      PRIVATE_CHANNEL_FORMAT = /private-(?<type>\w+)-(?<id>\d+)\.?\w*/

      post '/auth' do
        { channels: Hash[*authorized_channels.compact.flatten] }
      end

      private

        def authorized_channels
          params[:channels].map do |channel|
            [channel, authenticate(channel)] if authorized_for?(channel)
          end
        end

        def authorized_for?(channel)
          return true unless matches = PRIVATE_CHANNEL_FORMAT.match(channel)

          id = matches[:id].to_i
          case matches[:type]
          when 'user'
            signed_in? && current_user.id == id
          when 'repo'
            signed_in? && current_user.repository_ids.include?(id)
          when 'job'
            !!find_job(id)
          else
            false
          end
        end

        def find_job(id)
          Travis.run_service(:find_job, current_user, id: id, columns: ['id'])
        end

        def authenticate(channel)
          Travis.pusher[channel].authenticate(params[:socket_id])[:auth]
        end
    end
  end
end
