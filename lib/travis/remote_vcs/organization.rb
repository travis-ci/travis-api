# frozen_string_literal: true

require 'travis/remote_vcs/client'

module Travis
  class RemoteVCS
    class Organization < Client
      def destroy(org_id:)
        request(:delete, __method__, false) do |req|
          req.url "organizations/#{org_id}"
        end
      rescue ResponseError => e
        Travis.logger.error("Failed to destroy organization: #{e.message}")
        false
      end

      def restore(org_id:)
        request(:post, __method__, false) do |req|
          req.url "organizations/#{org_id}/restore"
        end
      rescue ResponseError => e
        Travis.logger.error("Failed to restore organization: #{e.message}")
        false
      end
    end
  end
end
