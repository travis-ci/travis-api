module Travis
  module API
    module V3
      V3 = self

      def load_dir(dir, recursive: true)
        Dir.glob("#{dir}/*.rb").sort.each { |f| require f[%r[(?<=lib/)travis/.+(?=\.rb$)]] }
        Dir.glob("#{dir}/*").sort.each { |dir| load_dir(dir) } if recursive
      end

      def response(payload, headers = {}, content_type: 'application/json'.freeze, status: 200)
        payload = JSON.pretty_generate(payload) unless payload.is_a? String
        headers = { 'Content-Type'.freeze => content_type, 'Content-Length'.freeze => payload.bytesize.to_s }.merge!(headers)
        [status, headers, [payload]]
      end

      def location(env)
        location = env['SCRIPT_NAME'.freeze].to_s + env['PATH_INFO'.freeze].to_s
        location << ??.freeze << env['QUERY_STRING'.freeze] if env['QUERY_STRING'.freeze] and not env['QUERY_STRING'.freeze].empty?
        location
      end

      extend self
      load_dir("#{__dir__}/v3/extensions")
      load_dir("#{__dir__}/v3")

      ClientError         = Error              .create(status: 400)
      ServerError         = Error              .create(status: 500)
      NotFound            = ClientError        .create(:resource, status: 404, template: '%s not found (or insufficient access)')

      AlreadySyncing      = ClientError        .create('sync already in progress', status: 409)
      BuildAlreadyRunning = ClientError        .create('build already running, cannot restart', status: 409)
      BuildNotCancelable  = ClientError        .create('build is not running, cannot cancel', status: 409)
      DuplicateResource   = ClientError        .create('resource already exists', status: 409)
      EntityMissing       = NotFound           .create(type: 'not_found')
      InsufficientAccess  = ClientError        .create(status: 403)
      JobAlreadyRunning   = ClientError        .create('job already running, cannot restart', status: 409)
      JobNotCancelable    = ClientError        .create('job is not running, cannot cancel', status: 409)
      LoginRequired       = ClientError        .create('login required', status: 403)
      MethodNotAllowed    = ClientError        .create('method not allowed', status: 405)
      NotImplemented      = ServerError        .create('request not (yet) implemented', status: 501)
      RequestLimitReached = ClientError        .create('request limit reached for resource', status: 429)
      WrongCredentials    = ClientError        .create('access denied',  status: 403)
      WrongParams         = ClientError        .create('wrong parameters')
    end
  end
end
