require 'travis/github'

module Travis
  module Github
    module Services
      class SetKey < Travis::Services::Base
        extend Travis::Instrumentation

        register :github_set_key

        def run
          delete_key if has_key? && params[:force]
          set_key unless has_key?
        end
        instrument :run

        def repo
          @repo ||= run_service(:find_repo, params.slice(:id, :owner_name, :name))
        end

        def has_key?
          !!key
        end

        private

        def keys
          @keys ||= remote_vcs_repository.keys(
            repository_id: repo.id,
            user_id: current_user.id
          )
        end

        def key
          keys.detect { |e| e['key'] == repo.key.encoded_public_key }
        end

        def set_key
          remote_vcs_repository.upload_key(
            repository_id: repo.id,
            user_id: current_user.id,
            read_only: !Travis::Features.owner_active?(:read_write_github_keys, repo.owner)
          )
        end

        def delete_key
          remote_vcs_repository.delete_key(
            repository_id: repo.id,
            user_id: current_user.id,
            id: key['id']
          )
        end

        def keys_path
          "repos/#{repo.slug}/keys"
        end

        def authenticated(&block)
          Travis::Github.authenticated(current_user, &block)
        end

        class Instrument < Notification::Instrument
          def run_completed
            publish(:msg => "for #{target.repo.slug}", :result => result)
          end
        end
        Instrument.attach_to(self)
      end
    end
  end
end
