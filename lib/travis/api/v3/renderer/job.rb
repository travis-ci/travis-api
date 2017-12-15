require 'travis/api/v3/config_obfuscator'

module Travis::API::V3
  class Renderer::Job < ModelRenderer
    representation(:minimal, :id)
    representation(:standard, *representations[:minimal], :allow_failure, :number, :state, :started_at, :finished_at, :build, :queue, :repository, :commit, :owner, :stage, :created_at, :updated_at)
    representation(:active, *representations[:standard])

    # TODO: I don't want to config be visible in the regular representation
    # as I want it to be visible only after adding include=job.config
    # we probably need to have a better way of doing this
    representation(:with_config, *representations[:minimal], :allow_failure, :number, :state, :started_at, :finished_at, :build, :queue, :repository, :commit, :owner, :stage, :created_at, :updated_at, :config)

    hidden_representations(:active)

    def created_at
      json_format_time_with_ms(model.created_at)
    end

    def updated_at
      json_format_time_with_ms(model.updated_at)
    end

    def config
      if include_config?
        ConfigObfuscator.new(model.config, model.repository.key).obfuscate
      end
    end

    private def include_config?
      include? 'job.config'.freeze
    end
  end
end
