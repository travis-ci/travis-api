require 'core_ext/hash/compact'

class Build
  class Config
    class Features < Struct.new(:config, :options)
      def run
        config = self.config
        config = remove_multi_os(config) unless options[:multi_os]
        config
      end

      def remove_multi_os(config)
        config.delete(:os)
        includes = config[:matrix].is_a?(Hash) && config[:matrix][:include]
        return config unless includes.is_a?(Array)
        includes = includes.each { |c| c.delete(:os) if c.is_a?(Hash) }.uniq
        config[:matrix][:include] = includes
        config
      end
    end
  end
end
