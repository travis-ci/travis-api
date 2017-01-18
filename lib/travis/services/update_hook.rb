require 'travis/support/instrumentation'
require 'travis/services/base'

module Travis
  module Services
    class UpdateHook < Base
      extend Travis::Instrumentation

      register :update_hook

      def run
        run_service(:github_set_hook, id: repo.id, enabled: enabled?)
        repo.update_column(:enabled, enabled?)
        sync_repo if enabled?
        true
      end
      instrument :run

      # TODO
      # def messages
      #   messages = []
      #   messages << { :notice => "The service hook was successfully #{enabled? ? 'enabled' : 'disabled'}." } if what?
      #   messages << { :error  => 'The service hook could not be set.' } unless what?
      #   messages
      # end

      def repo
        @repo ||= current_user.service_hook(params.slice(:id, :owner_name, :name))
      end

      def enabled?
        enabled = params[:enabled]
        enabled = { 'true' => true, 'false' => false }[enabled] if enabled.is_a?(String)
        !!enabled
      end

      def sync_repo
        logger.info("Synchronizing repo via Sidekiq: #{repo.slug} id=#{repo.id}")
        ::Sidekiq::Client.push(
          'queue' => 'sync',
          'class' => 'Travis::GithubSync::Worker',
          'args'  => [:sync_repo, { repo_id: repo.id, user_id: current_user.id }]
        )
      end

      class Instrument < Notification::Instrument
        def run_completed
          publish(
            :msg => "for #{target.repo.slug} enabled=#{target.enabled?.inspect} (#{target.current_user.login})",
            :result => result
          )
        end
      end
      Instrument.attach_to(self)
    end
  end
end
