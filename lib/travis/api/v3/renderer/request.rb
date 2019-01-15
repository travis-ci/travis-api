module Travis::API::V3
  class Renderer::Request < ModelRenderer
    representation(:minimal,  :id, :state, :result, :message)
    representation(:standard, *representations[:minimal], :repository, :branch_name, :commit, :builds, :owner, :created_at, :event_type, :base_commit, :head_commit)

    def self.available_attributes
      super + ['yaml_config']
    end

    def yaml_config
      model.yaml_config || "---\nerror: No YAML found for this request."
    end
  end
end
