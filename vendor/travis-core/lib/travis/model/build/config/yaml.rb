class Build
  class Config
    class Yaml < Struct.new(:config, :options)
      def run
        normalize(config)
      end

      def normalize(hash)
        Hash[hash.map { |key, value| [key == true ? :on : key, value] }]
      end
    end
  end
end

