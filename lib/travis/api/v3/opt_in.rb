module Travis::API::V3
  class OptIn
    attr_reader :legacy_stack, :prefix, :router, :accept, :version_header

    def initialize(legacy_stack, prefix: '/v3', router: Router.new, accept: 'application/vnd.travis-ci.3+', version_header: 'Travis-API-Version')
      @legacy_stack   = legacy_stack
      @prefix         = prefix
      @router         = router
      @accept         = accept
      @version_header = "HTTP_#{version_header.upcase.gsub(/\W/, '_')}"
    end

    def call(env)
      return redirect(env) if redirect?(env)

      # Do we have to do this for V3??!
      env.merge({
        'SCRIPT_NAME'.freeze => env['SCRIPT_NAME'.freeze] + prefix,
        'PATH_INFO'.freeze   => env['PATH_INFO'.freeze][prefix.size..-1]
      })

      result          = @router.call(env)
      result, missing = nil, result if cascade?(*result)

      result = result
      pick(result, missing)
    end

    def pick(result, missing)
      return result if missing.nil?
      return result if result[0] != 404
      missing
    end

    def redirect?(env)
      env['PATH_INFO'.freeze] == prefix
    end

    def redirect(env)
      [307, {'Location'.freeze => env['SCRIPT_NAME'.freeze] + prefix + ?/.freeze, 'Conent-Type'.freeze => 'text/plain'.freeze}, []]
    end

    def cascade?(status, headers, body)
      status % 100 == 4 and headers['X-Cascade'.freeze] == 'pass'.freeze
    end
  end
end
