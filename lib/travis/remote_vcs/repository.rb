# frozen_string_literal: true

require 'travis/remote_vcs/client'

module Travis
  class RemoteVCS
    class Repository < Client
      def set_hook(repository_id:, user_id:)
        resp = connection.post do |req|
          req.url "repos/#{repository_id}/hook"
          req.params['user_id'] = user_id
        end
        resp.success?
      end
    end
  end
end
