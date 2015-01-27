module Travis
  module API
    module V3
      V3 = self

      def load_dir(dir, recursive: true)
        Dir.glob("#{dir}/*.rb").sort.each { |f| require f[%r[(?<=lib/).+(?=\.rb$)]] }
        Dir.glob("#{dir}/*").sort.each { |dir| load_dir(dir) } if recursive
      end

      def response(payload, headers = {}, content_type: 'application/json'.freeze, status: 200)
        payload = JSON.pretty_generate(payload) unless payload.is_a? String
        headers = { 'Content-Type'.freeze => content_type, 'Content-Length'.freeze => payload.bytesize.to_s }.merge!(headers)
        [status, headers, [payload] ]
      end

      extend self
      load_dir("#{__dir__}/v3")

      ClientError      = Error        .create(status: 400)
      NotFound         = ClientError  .create(:resource, status: 404, template: '%s not found (or insufficient access)')
      EnitityMissing   = NotFound     .create(type: 'not_found')
      WrongCredentials = ClientError  .create('access denied',  status: 403)
      LoginRequired    = ClientError  .create('login required', status: 403)
      WrongParams      = ClientError  .create('wrong parameters')
    end
  end
end
