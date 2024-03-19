module Travis::API::V3
  class Queries::Request < Query
    params :id, :message, :branch, :sha, :tag_name, :merge_mode, :config, :configs, :token, prefix: :request

    def find
      raise WrongParams, 'missing request.id'.freeze unless id
      relation = Models::Request
      relation = relation.includes(raw_configurations: :raw_config) if includes?('request.raw_configs')
      relation = relation.includes(:config) if includes?('request.config')
      request = relation.find_by_id(id)
      # not sure why includes(:messages) does not include the association
      request.messages = messages(request) if includes?('request.messages')
      request
    end

    def messages(request)
      Queries::Messages.new(params, :message).for_request(request)
    end

    def schedule(repository, user)
      raise ServerError, 'repository does not have a provider id'.freeze unless repository.vcs_id || repository.github_id
      raise WrongParams, 'missing user'.freeze unless user and user.id

      request = create_request(repository)

      payload = {
        repository: {
          id: repository.github_id || repository.vcs_id,
          vcs_type: repository.vcs_type,
          owner_name: repository.owner_name,
          name: repository.name ,
        },
        user: {
          id: user.id
        },
        id: request.id,
        message: message,
        branch: branch || repository.default_branch.name,
        tag_name: tag_name,
        sha: sha,
        configs: request_configs,
        # BC, remove once everyone is on yml/configs, coordinate with Gatekeeper
        merge_mode: merge_mode,
        config: to_str(config),
      }

      ::Travis::API::Sidekiq.gatekeeper(
        type: 'api'.freeze,
        credentials: { token: token },
        payload: JSON.dump(payload)
      )
      compact(payload)
    end

    private

      def request_configs
        configs = self.configs
        configs = configs.map { |config| normalize_config(config) } if configs
        configs ||= [{ config: to_str(config), mode: merge_mode }] if config
        configs
      end

      def normalize_config(config)
        config['config'] = to_str(config['config'])
        config['mode'] = config.delete('merge_mode') if config['merge_mode']
        config
      end

      def to_str(config)
        config.is_a?(Hash) ? JSON.dump(config) : config
      end

      def create_request(repository)
        Models::Request.create!(
          event_type: :api,
          state: :pending,
          repository: repository,
          owner: repository.owner,
          private: repository.private
        )
      end

      def compact(hash)
        hash.reject { |_, value| value.nil? }.to_h
      end
  end
end
