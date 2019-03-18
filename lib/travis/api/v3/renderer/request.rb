module Travis::API::V3
  class Renderer::Request < ModelRenderer
    representation(:minimal,  :id, :state, :result, :message)
    representation(:standard, *representations[:minimal], :repository, :branch_name, :commit, :builds, :owner, :created_at, :event_type, :base_commit, :head_commit)

    def self.available_attributes
      super + ['raw_configs']
    end

    def raw_configs
      configs = model.raw_configurations.to_a
      configs.any? ? configs : [{ config: model.yaml_config.yaml, source: '.travis.yml' }]
    end
  end
end
