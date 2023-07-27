require 'faraday/error'
require 'travis/services/base'

# TODO extract github specific stuff to a separate service

module Travis
  module Services
    class FindAdmin < Base
      extend Travis::Instrumentation
      include Travis::Logging

      register :find_admin

      def run
        if repository
          admin = candidates.first
          admin || raise_admin_missing
        else
          error "[github-admin] repository is nil: #{params.inspect}"
          raise Travis::RepositoryMissing, "no repository given"
        end
      end
      instrument :run

      def repository
        params[:repository]
      end

      private

        def candidates
          User.with_github_token.with_permissions(:repository_id => repository.id, :admin => true)
        end

        def validate(user)
          Timeout.timeout(2) do
            data = repository_data(user)
            if data['permissions'] && data['permissions']['admin']
              user
            else
              info "[github-admin] #{user.login} no longer has admin access to #{repository.slug}"
              update(user, data['permissions'])
              false
            end
          end
        rescue error
          handle_error(user, error)
          false
        end

        def handle_error(user, error)
          status = error.info[:response_status]
          case status
          when 401
            error "[github-admin] token for #{user.login} no longer valid"
            # user.update!(:github_oauth_token => "")
          when 404
            info "[github-admin] #{user.login} no longer has any access to #{repository.slug}"
            update(user, {})
          else
            error "[github-admin] error retrieving repository info for #{repository.slug} for #{user.login}: #{error.message}"
          end
        end

        # TODO should this not be memoized?
        def repository_data(user)
          Travis::RemoteVCS::Repository.new.show(
            repository_id: repository.id,
            admin_id: user.id
          )
        end

        def update(user, permissions)
          user.update!(:permissions => permissions)
        end

        def raise_admin_missing
          raise Travis::AdminMissing.new("no admin available for #{repository.slug}")
        end

        class Instrument < Notification::Instrument
          def run_completed
            publish(
              msg: "for #{target.repository.slug}: #{result.login}",
              result: result
            )
          end
        end
        Instrument.attach_to(self)
    end
  end
end
