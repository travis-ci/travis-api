require 'travis/rollout'

module Travis::API::V3
  class Renderer::UserSettings < CollectionRenderer
    type           :settings
    collection_key :settings

    def render
      super.tap do |result|
        result[:settings].select!(&method(:allow?))
      end
    end

    def allow?(setting)
      case setting[:name]
      when :allow_config_imports then allow_config_imports?
      when :config_validation    then allow_config_validation?
      else true
      end
    end

    def allow_config_imports?
      repo.private?
    end

    def allow_config_validation?
      Travis::Rollout.matches?(:config_validation, uid: repo.owner_id, owner: repo.owner_name)
    end

    def repo
      @repo ||= Repository.find(list.repository_id)
    end
  end
end
