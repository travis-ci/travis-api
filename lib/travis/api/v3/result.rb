module Travis::API::V3
  class Result
    attr_accessor :access_control, :type, :resource, :status, :href, :meta_data

    def initialize(access_control, type, resource = [], status: 200, **meta_data)
      @access_control, @type, @resource, @status, @meta_data = access_control, type, resource, status, meta_data
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
      Renderer[type].render(resource,
        href:           href,
        script_name:    env['SCRIPT_NAME'.freeze],
        include:        include,
        access_control: access_control,
        meta_data:      meta_data)
    end

    def method_missing(method, *args)
      return super unless method.to_sym == type.to_sym
      raise ArgumentError, 'wrong number of arguments (1 for 0)'.freeze if args.any?
      resource
    end
  end
end
