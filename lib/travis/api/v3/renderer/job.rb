require 'travis/api/v3/config_obfuscator'

module Travis::API::V3
  class Renderer::Job < ModelRenderer
    representation(:minimal, :id)
    representation(:standard, *representations[:minimal], :allow_failure, :number, :state, :started_at, :finished_at, :build, :queue, :repository, :commit, :owner, :stage, :created_at, :updated_at, :private, :restarted_at, :restarted_by, :vm_size)
    representation(:active, *representations[:standard])

    # TODO: I don't want to config be visible in the regular representation
    # as I want it to be visible only after adding include=job.config
    # we probably need to have a better way of doing this
    representation(:with_config, *representations[:minimal], :allow_failure, :number, :state, :started_at, :finished_at, :build, :queue, :repository, :commit, :owner, :stage, :created_at, :updated_at, :restarted_at, :restarted_by, :vm_size, :config)

    hidden_representations(:with_config)
    hidden_representations(:active)

    def self.available_attributes
      super + ['log_complete']
    end

    def created_at
      json_format_time_with_ms(model.created_at)
    end

    def updated_at
      json_format_time_with_ms(model.updated_at)
    end

    def restarted_by
      return nil unless restarter = model.restarter
      {
        '@type' => 'user',
        '@representation' => 'minimal'.freeze,
        'id' => restarter.id,
        'login' => restarter.login
      }
    end

    def config
      if include_config?
        ConfigObfuscator.new(model.config, model.repository.key).obfuscate
      end
    end

    def log_complete
      if include_log_complete?
        return model.log_complete
      end
    end

    private def include_config?
      include? 'job.config'.freeze
    end

    private def include_log_complete?
      include? 'job.log_complete'.freeze
    end
  end
end
