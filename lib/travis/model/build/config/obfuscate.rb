require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/array/wrap'
require 'travis/secure_config'

class Build
  class Config
    class Obfuscate < Struct.new(:config, :options)
      ENV_VAR_PATTERN = /(?<=\=)(?:(?<q>['"]).*?[^\\]\k<q>|(.*?)(?= \w+=|$))/

      def run
        config = self.config.except(:source_key)
        config[:env] = obfuscate(config[:env]) if config[:env]
        config
      end

      private

        def obfuscate(env)
          Array.wrap(env).map do |value|
            obfuscate_values(value).join(' ')
          end
        end

        def obfuscate_values(values)
          Array.wrap(values).compact.map do |value|
            obfuscate_value(value)
          end
        end

        def obfuscate_value(value)
          secure.decrypt(value) do |decrypted|
            obfuscate_env_vars(decrypted)
          end
        end

        def obfuscate_env_vars(line)
          if line.respond_to?(:gsub)
            line.gsub(ENV_VAR_PATTERN) { |val| '[secure]' }
          else
            '[One of the secure variables in your .travis.yml has an invalid format.]'
          end
        end

        def secure
          @secure ||= Travis::SecureConfig.new(key)
        end

        def key
          @key ||= options[:key_fetcher].call
        end
    end
  end
end
