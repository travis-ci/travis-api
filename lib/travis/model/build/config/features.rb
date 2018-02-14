require 'core_ext/hash/compact'

class Build
  class Config
    class Features < Struct.new(:config, :options)
      def run
        config = self.config
        config
      end
    end
  end
end
