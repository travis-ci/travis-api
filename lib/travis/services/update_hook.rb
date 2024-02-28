require 'travis/support/instrumentation'
require 'travis/services/base'

module Travis
  module Services
    class UpdateHook < Base
      extend Travis::Instrumentation

      register :update_hook

      def run
        run_service(:github_set_hook, id: repo.id, active: active?)
        run_service(:github_set_key, params) if repo.private? || Travis.config.enterprise
        repo.update_column(:active, active?)
        sync_repo if active?
        true
      end
      instrument :run

      # TODO
      # def messages
      #   messages = []
      #   messages << { :notice => "The service hook was successfully #{active? ? 'enabled' : 'disabled'}." } if what?
      #   messages << { :error  => 'The service hook could not be set.' } unless what?
      #   messages
      # end

      def repo
        @repo ||= current_user.service_hook(params.slice(:id, :owner_name, :name))
      end

      def active?
        active = params[:active]
        active = { 'true' => true, 'false' => false }[active] if active.is_a?(String)
        !!active
      end

      def sync_repo
        logger.info("Synchronizing repo via Sidekiq: #{repo.slug} id=#{repo.id}")
        ::Sidekiq::Client.push(
          'queue' => 'sync',
          'class' => 'Travis::GithubSync::Worker',
          'args'  => [:sync_repo, { repo_id: repo.id, user_id: current_user.id }].map! {|arg| arg.to_json }
        )
      end

      class Instrument < Notification::Instrument
        def run_completed
          publish(
            :msg => "for #{target.repo.slug} active=#{target.active?.inspect} (#{target.current_user.login})",
            :result => result
          )
        end
      end
      Instrument.attach_to(self)
    end
  end
end
