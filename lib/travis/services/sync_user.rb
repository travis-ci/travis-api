require 'travis/sidekiq/synchronize_user'
require 'travis/services/base'

module Travis
  module Services
    class SyncUser < Base
      register :sync_user

      def run
        trigger_sync unless user.syncing?
      end

      def trigger_sync
        logger.info("Synchronizing via Sidekiq for user: #{user.login}")
        Travis::Sidekiq::SynchronizeUser.perform_async(user.id)
        user.update_column(:is_syncing, true)
        true
      end

      def user
        # TODO check that clients are only passing the id
        @user ||= current_user || User.find(params[:id])
      end
    end
  end
end
