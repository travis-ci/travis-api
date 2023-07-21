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
        ::Sidekiq::Client.push(
          'queue' => 'sync',
          'class' => 'Travis::GithubSync::Worker',
          'args'  => [:sync_user, { user_id: user.id }].map! { |arg| arg.to_json }
        )
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
