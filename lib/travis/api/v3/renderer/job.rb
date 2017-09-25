module Travis::API::V3
  class Renderer::Job < ModelRenderer
    representation(:minimal, :id)
    representation(:standard, *representations[:minimal], :allow_failure, :number, :state, :started_at, :finished_at, :build, :queue, :repository, :commit, :owner, :stage, :config)
    representation(:active, *representations[:standard])

    hidden_representations(:active)
  end

  def config
    normalize_config(model.config).deep_dup.tap do |config|
      delete_addons(config)
      config.delete(:source_key)
      if config[:env]
        obfuscated_env = process_env(config[:env]) { |env| obfuscate_env(env) }
        config[:env] = obfuscated_env ? obfuscated_env.join(' ') : nil
      end
      if config[:global_env]
        obfuscated_env = process_env(config[:global_env]) { |env| obfuscate_env(env) }
        config[:global_env] = obfuscated_env ? obfuscated_env.join(' ') : nil
      end
    end
  end

  private
    def normalize_config(config)
      config = YAML.load(config) if config.is_a? String
      config = config ? config.deep_symbolize_keys : {}

      if config[:deploy]
        if config[:addons].is_a? Hash
          config[:addons][:deploy] = config.delete(:deploy)
        else
          config.delete(:addons)
          config[:addons] = { deploy: config.delete(:deploy) }
        end
      end

      config
    end

    def delete_addons(config)
      if config[:addons].is_a?(Hash)
        config[:addons].keep_if { |key, _| SAFELISTED_ADDONS.include? key.to_s }
      else
        config.delete(:addons)
      end
    end

end
