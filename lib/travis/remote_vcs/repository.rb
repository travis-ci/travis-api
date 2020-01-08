# frozen_string_literal: true

require 'travis/remote_vcs/client'

module Travis
  class RemoteVCS
    class Repository < Client
      def set_hook(repository_id:, user_id:, activate: true)
        request(activate ? :post : :delete, __method__) do |req|
          req.url "repos/#{repository_id}/hook"
          req.params['user_id'] = user_id
        end
      rescue ResponseError
        false
      end

      def keys(repository_id:, user_id:)
        request(:get, __method__) do |req|
          req.url "repos/#{repository_id}/keys"
          req.params['user_id'] = user_id
        end
      rescue ResponseError
        []
      end

      def upload_key(repository_id:, user_id:, read_only:)
        request(:post, __method__) do |req|
          req.url "repos/#{repository_id}/keys"
          req.params['user_id'] = user_id
          req.params['read_only'] = read_only
        end
      rescue ResponseError
        false
      end

      def delete_key(repository_id:, user_id:, id:)
        request(:delete, __method__) do |req|
          req.url "repos/#{repository_id}/keys/#{id}"
          req.params['user_id'] = user_id
        end
      rescue ResponseError
        false
      end
    end
  end
end
