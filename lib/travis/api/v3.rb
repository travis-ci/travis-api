module Travis
  module API
    module V3
      V3 = self

      def load_dir(dir, recursive: true)
        Dir.glob("#{dir}/*.rb").each { |f| require f[%r[(?<=lib/).+(?=\.rb$)]] }
        Dir.glob("#{dir}/*").each { |dir| load_dir(dir) } if recursive
      end

      def response(payload, headers = {}, content_type: 'application/json'.freeze, status: 200)
        payload = JSON.pretty_generate(payload) unless payload.is_a? String
        headers = { 'Content-Type'.freeze => content_type, 'Content-Length'.freeze => payload.bytesize.to_s }.merge!(headers)
        [200, headers, [payload] ]
      end

      extend self
      load_dir("#{__dir__}/v3")
    end
  end
end
