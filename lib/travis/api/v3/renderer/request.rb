module Travis::API::V3
  class Renderer::Request < ModelRenderer
    representation(:minimal,  :id, :state, :result, :message, :pull_request_mergeable)
    representation(:standard, *representations[:minimal], :repository, :branch_name, :commit, :builds, :owner, :created_at, :event_type, :base_commit, :head_commit, :messages, :config, :raw_configs)

    def self.available_attributes
      super + %w(yaml_config)
    end

    def config
      config_ = model.config.is_a?(String) ? JSON.parse(model.config) : model.config
      config_.deep_symbolize_keys.reject { |key, _| key == :'.result' }
    end

    def yaml_config
      model.yaml_config&.yaml
    end

    def raw_configs
      configs = model.raw_configurations.to_a
      configs = configs.sort_by(&:id)
      configs = configs.uniq(&:source)
      return configs if configs.any?
      return [] unless model.yaml_config
      [{ config: model.yaml_config.yaml, source: '.travis.yml' }]
    end
  end
end
