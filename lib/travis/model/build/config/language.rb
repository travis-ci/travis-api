require 'active_support/core_ext/array/wrap'

class Build
  class Config
    class Language < Struct.new(:config, :options)
      def run
        config[:language] = Array.wrap(config[:language]).first.to_s.downcase
        config[:language] = DEFAULT_LANG if config[:language].empty?
        config.select { |key, _| include_key?(key) }
      end

      private

      def include_key?(key)
        matrix_keys.include?(key) || !known_env_key?(key)
      end

      def matrix_keys
        Config.matrix_keys(config, options)
      end

      def known_env_key?(key)
        (ENV_KEYS | EXPANSION_KEYS_FEATURE).include?(key)
      end
    end
  end
end
