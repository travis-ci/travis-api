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
          if Travis::Features.user_active?(:use_vcs, current_user) || !current_user.github?
            @keys ||= remote_vcs_repository.keys(
              repository_id: repo.id,
              user_id: current_user.id
            )
          else
            @keys ||= authenticated do
              GH[keys_path]
            end
          end
        end

        def key
          keys.detect { |e| e['key'] == repo.key.encoded_public_key }
        end

        def set_key
          puts "SET KEY TO THE REPOSITORY #{current_user.login} == #{current_user.github?}"
          read_only = !Travis::Features.owner_active?(:read_write_github_keys, repo.owner)
          if Travis::Features.user_active?(:use_vcs, current_user) || !current_user.github?
            remote_vcs_repository.upload_key(
              repository_id: repo.id,
              user_id: current_user.id,
              read_only: read_only
            )
          else
            authenticated do
              GH.post keys_path, {
                title: Travis.config.host.to_s,
                key: repo.key.encoded_public_key,
                read_only: read_only
              }
            end
          end
        end

        def delete_key
          puts "DELETE KEY #{current_user.login} == #{current_user.github?}"
          if Travis::Features.user_active?(:use_vcs, current_user) || !current_user.github?
            remote_vcs_repository.delete_key(
              repository_id: repo.id,
              user_id: current_user.id,
              id: key['id']
            )
          else
            authenticated do
              GH.delete "#{keys_path}/#{key['id']}" #key['_links']['self']['href']
              @keys = []
            end
          end
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
