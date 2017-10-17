require 'travis/api/v3/config_obfuscator'

module Travis::API::V3
  class Renderer::Job < ModelRenderer
    representation(:minimal, :id)
    representation(:standard, *representations[:minimal], :allow_failure, :number, :state, :started_at, :finished_at, :build, :queue, :repository, :commit, :owner, :stage, :updated_at, :config)
    representation(:active, *representations[:standard])

    hidden_representations(:active)

    def updated_at
      json_format_time_with_ms(model.updated_at)
    end

    def config
      ConfigObfuscator.new(model.config, model.repository.key).obfuscate
    end
  end
end
