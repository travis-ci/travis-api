module Travis::API::V3
  class Result
    attr_accessor :type, :resource, :status, :href

    def initialize(type, resource = [], status: 200)
      @type, @resource, @status = type, resource, status
    end

    def respond_to_missing?(method, *)
      super or method.to_sym == type.to_sym
    end

    def <<(value)
      resource << value
      self
    end

    def render(params, env)
      href    = self.href
      href    = V3.location(env) if href.nil? and env['REQUEST_METHOD'.freeze] == 'GET'.freeze
      include = params['include'.freeze].to_s.split(?,.freeze)
      Renderer[type].render(resource, href: href, script_name: env['SCRIPT_NAME'.freeze], include: include)
    end

    def method_missing(method, *args)
      return super unless method.to_sym == type.to_sym
      raise ArgumentError, 'wrong number of arguments (1 for 0)'.freeze if args.any?
      resource
    end
  end
end
