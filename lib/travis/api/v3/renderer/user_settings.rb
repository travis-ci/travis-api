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
      return unless setting

      case setting[:name]
      when :allow_config_imports then repo.private?
      else true
      end
    end

    def repo
      @repo ||= Repository.find(list.repository_id)
    end
  end
end
