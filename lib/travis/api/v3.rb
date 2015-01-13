module Travis
  module API
    module V3
      def load_dir(dir, recursive: true)
        Dir.glob("#{dir}/*.rb").each { |f| require f[%r[(?<=lib/).+(?=\.rb$)]] }
        Dir.glob("#{dir}/*").each { |dir| load_dir(dir) } if recursive
      end

      extend self
      load_dir("#{__dir__}/v3")
    end
  end
end
