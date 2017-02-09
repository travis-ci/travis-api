module Travis::API::V3
  class Router
    include Travis::API::V3
    attr_accessor :routes, :metrics_processor

    def initialize(routes = Routes)
      @routes            = routes
      @metrics_processor = Metrics::Processor.new

      metrics_processor.start
      routes.draw_routes
    end

    def call(env)
      return service_index(env) if env['PATH_INFO'.freeze] == ?/.freeze or env['PATH_INFO'.freeze] == ''.freeze
      metrics         = @metrics_processor.create
      access_control  = AccessControl.new(env)
      env_params      = params(env)
      factory, params = routes.factory_for(env['REQUEST_METHOD'.freeze], env['PATH_INFO'.freeze])

      content_type = get_content_type(env)

      raise NotFound unless factory
      metrics.name_after(factory)

      filtered = factory.filter_params(env_params)
      service  = factory.new(access_control, filtered.merge(params), env['rack.input'.freeze])

      metrics.tick(:prepare)
      result   = service.run
      metrics.tick(:service)

      env_params.each_key { |key| result.ignored_param(key, reason: "not safelisted".freeze) unless filtered.include?(key) }
      response = render(result, env_params, env, content_type)

      metrics.tick(:renderer)
      metrics.success(status: response[0])
      response
    rescue Error => error
      metrics.tick(:service)

      result   = Result.new(access_control, :error, error)
      response = V3.response(result.render(env_params, env),  {}, content_type: content_type, status: error.status)

      metrics.tick(:rendered)
      metrics.failure(status: error.status)

      response
    end

    def render(result, env_params, env, content_type)
      V3.response(result.render(env_params, env), {}, content_type: content_type, status: result.status)
    end

    def service_index(env)
      ServiceIndex.for(env, routes).render(env)
    end

    def get_content_type(env)
      default_content_type = 'application/json'.freeze
      allowed_content_types = [default_content_type, 'text/plain'.freeze]
      content_type = env.fetch('HTTP_ACCEPT'.freeze, default_content_type)
      allowed_content_types.find{ |d| d == content_type} || default_content_type
    end

    def params(env)
      request    = Rack::Request.new(env)
      params     = request.params
      media_type = request.media_type

      if media_type == 'application/json'.freeze or media_type == 'text/json'.freeze
        request.body.rewind
        json_params = env['travis.input.json'.freeze] ||= JSON.load(request.body)
        params.merge! json_params if json_params.is_a? Hash
      end

      params
    end
  end
end
