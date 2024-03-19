module Travis::API::V3
  class ConfigObfuscator
   attr_reader :config, :key

    SAFELISTED_ADDONS = %w(
      apt
      apt_packages
      apt_sources
      chrome
      firefox
      hosts
      mariadb
      postgresql
      ssh_known_hosts
    ).freeze

    def initialize(config, key)
      @config = config
      @key    = key
    end

    def obfuscate
      normalize_config(config).deep_dup.tap do |config|
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

      def delete_addons(config)
        if config[:addons].is_a?(Hash)
          config[:addons].keep_if { |key, _| SAFELISTED_ADDONS.include? key.to_s }
        else
          config.delete(:addons)
        end
      end

      def normalize_config(config)
        config = YAML.load(config, aliases: true) if config.is_a? String
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

      def process_env(env)
        env = [env] unless env.is_a?(Array)
        env = normalize_env(env)
        env = yield(env)
        env.compact.presence
      end

      def normalize_env(env)
        env.map do |line|
          if line.is_a?(Hash) && !line.has_key?(:secure)
            line.map do |key, value|
              value = '[secure]' if value.is_a?(Hash) && value.key?(:secure)
              "#{key}=#{value}"
            end.join(' ')
          else
            line
          end
        end
      end

      def obfuscate_env(vars)
        vars = [vars] unless vars.is_a?(Array)
        vars.compact.map do |var|
          secure.decrypt(var) do |decrypted|
            next unless decrypted
            if decrypted.include?('=')
              "#{decrypted.to_s.split('=').first}=[secure]"
            else
              '[secure]'
            end
           end
         end
      end

      def secure
        Travis::SecureConfig.new(key)
      end
  end
end
