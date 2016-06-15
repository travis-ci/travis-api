require 'core_ext/hash/compact'

class Build
  class Config
    class Env < Struct.new(:config, :options)
      def run
        case config[:env]
        when Hash
          config.merge(normalize_hash(config[:env])).compact
        when Array
          config.merge(env: config[:env].map { |value| normalize_value(value) })
        else
          config
        end
      end

      def normalize_hash(env)
        if env[:global] || env[:matrix]
          { global_env: normalize_values(env[:global]), env: normalize_values(env[:matrix]) }
        else
          { env: normalize_values(env) }
        end
      end

      def normalize_values(values)
        values = [values].compact unless values.is_a?(Array)
        values.map { |value| normalize_value(value) } unless values.empty?
      end

      def normalize_value(value)
        case value
        when Hash
          to_env_var(value)
        when Array
          value.map { |value| to_env_var(value) }
        else
          value
        end
      end

      def to_env_var(hash)
        if hash.is_a?(Hash) && !hash.key?(:secure)
          hash.map { |name, value| "#{name}=#{value}" }.join(' ')
        else
          hash
        end
      end
    end
  end
end
