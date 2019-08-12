# frozen_string_literal: true

require 'travis/remote_vcs/client'

module Travis
  class RemoteVCS
    class Repository < Client
      def set_hook(repository_id:, user_id:, activate: true)
        resp = connection.send(activate ? :post : :delete) do |req|
          req.url "repos/#{repository_id}/hook"
          req.params['user_id'] = user_id
        end
        resp.success?
      end

      def upload_key(repository_id:, user_id:, read_only:)
        resp = connection.post do |req|
          req.url "repos/#{repository_id}/key"
          req.params['user_id'] = user_id
          req.params['read_only'] = read_only
        end
        resp.success?
      end
    end
  end
end
