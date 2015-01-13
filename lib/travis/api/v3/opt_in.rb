module Travis::API::V3
  class OptIn
    attr_reader :legacy_stack, :prefix, :router, :accept, :version_header

    def initialize(legacy_stack, prefix: '/v3/', router: Router.new, accept: 'application/vnd.travis-ci.3+', version_header: 'Travis-API-Version')
      @legacy_stack   = legacy_stack
      @prefix         = prefix
      @router         = router
      @accept         = accept
      @version_header = "HTTP_#{version_header.upcase.gsub(/\W/, '_')}"
    end

    def call(env)
      return redirect(env) if redirect?(env)

      if matched        = matching_env(env)
        result          = @router.call(matched)
        result, missing = nil, result if cascade?(*result)
      end

      result = result || legacy_stack.call(env)
      pick(result, missing)
    end

    def pick(result, missing)
      return result if missing.nil?
      return result if result[0] != 404
      missing
    end

    def redirect?(env)
      env['PATH_INFO'.freeze] + ?/.freeze == prefix
    end

    def redirect(env)
      [307, {'Location'.freeze => env['SCRIPT_NAME'.freeze] + prefix, 'Conent-Type'.freeze => 'text/plain'.freeze}, []]
    end

    def cascade?(status, headers, body)
      status % 100 == 4 and headers['X-Cascade'.freeze] == 'pass'.freeze
    end

    def matching_env(env)
      for_v3 = from_prefix(env) || from_accept(env) || from_version_header(env)
      for_v3 == true ? env : for_v3
    end

    def from_prefix(env)
      return unless prefix and env['PATH_INFO'.freeze].start_with?(prefix)
      env.merge({
        'SCRIPT_NAME'.freeze => env['SCRIPT_NAME'.freeze] + prefix,
        'PATH_INFO'.freeze   => env['PATH_INFO'.freeze][prefix.size..-1]
      })
    end

    def from_accept(env)
      env['HTTP_ACCEPT'.freeze].include?(accept) if accept and env.include?('HTTP_ACCEPT'.freeze)
    end

    def from_version_header(env)
      env[version_header] == '3'.freeze if version_header and env.include?(version_header)
    end
  end
end
