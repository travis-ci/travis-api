module Travis
  module API
    module V3
      V3 = self

      def load_dir(dir, recursive: true)
        Dir.glob("#{dir}/*.rb").sort.each { |f| require f[%r[(?<=lib/)travis/.+(?=\.rb$)]] }
        Dir.glob("#{dir}/*").sort.each { |dir| load_dir(dir) } if recursive
      end

      def response(payload, headers = {}, content_type: , status: 200)
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

      AdminAccessRequired = ClientError        .create('admin access to this repo required',  status: 403)
      AlreadySyncing      = ClientError        .create('sync already in progress', status: 409)
      BuildAlreadyRunning = ClientError        .create('build already running, cannot restart', status: 409)
      BuildNotCancelable  = ClientError        .create('build is not running, cannot cancel', status: 409)
      DuplicateResource   = ClientError        .create('resource already exists', status: 409)
      EntityMissing       = NotFound           .create(type: 'not_found')
      InsufficientAccess  = ClientError        .create(status: 403)
      JobAlreadyRunning   = ClientError        .create('job already running, cannot restart', status: 409)
      JobNotCancelable    = ClientError        .create('job is not running, cannot cancel', status: 409)
      JobUnfinished       = ClientError        .create('job still running, cannot remove log yet', status: 409)
      LogAlreadyRemoved   = ClientError        .create('log has already been removed', status: 409)
      LogExpired          = ClientError        .create("We're sorry, but this data is not available anymore. Please check the repository settings in Travis CI.", status: 403)
      LogAccessDenied     = ClientError        .create("We're sorry, but this data is not available. Please check the repository settings in Travis CI.", status: 403)
      LoginRequired       = ClientError        .create('login required', status: 403)
      MethodNotAllowed    = ClientError        .create('method not allowed', status: 405)
      NotImplemented      = ServerError        .create('request not (yet) implemented', status: 501)
      PrivateRepoFeature  = ClientError        .create('this feature is only available on private repositories and for Travis CI Enterprise customers', status: 403)
      RepositoryInactive  = ClientError        .create('cannot create requests on an inactive repository', status: 406)
      RepoSshKeyMissing   = ClientError        .create('request cannot be completed because the repo ssh key is still pending to be created. please retry in a bit, or try syncing the repository if this condition does not resolve', status: 409)
      RequestLimitReached = ClientError        .create('request limit reached for resource', status: 429)
      SourceUnknown       = NotFound           .create('source unknown', status: 400)
      UnprocessableEntity = ClientError        .create('request unable to be processed due to semantic errors', status: 422)
      WrongCredentials    = ClientError        .create('access denied',  status: 403)
      WrongParams         = ClientError        .create('wrong parameters')
      TimeoutError        = ServerError        .create("Credit card processing is currently taking longer than expected. Please check back in a few minutes and refresh the screen at that time.<br>We apologize for the inconvenience and appreciate your patience.", status: 504)
    end
  end
end
