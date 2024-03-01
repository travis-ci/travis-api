module Travis::API::V3
  class Result
    attr_accessor :access_control, :type, :resource, :status, :href, :meta_data, :warnings

    def initialize(access_control:, type:, resource:, status: 200, **meta_data)
      @warnings = []
      @access_control, @type, @resource, @status, @meta_data = access_control, type, resource, status, meta_data
    end

    def respond_to_missing?(method, *)
      super or method.to_sym == type.to_sym
    end

    def warn(message,**info)
      warnings << { :@type => 'warning'.freeze, :message => message, **info }
    end

    def ignored_param(param, reason: nil, **info)
      message = reason ? "query parameter #{param} #{reason}, ignored" : "query parameter #{param} ignored"
      warn(message, warning_type: :ignored_parameter, parameter: param, **info)
    end

    def deprecated_param(param, reason: nil, **info)
      message = reason ? "#{param} will soon be deprecated. Please use #{reason} instead" : "query parameter #{param} deprecated"
      warn(message, warning_type: :deprecated_parameter, parameter: param, **info)
    end

    def render(params, env)
      href    = self.href
      href    = V3.location(env) if href.nil? and env['REQUEST_METHOD'.freeze] == 'GET'.freeze
      include = params.to_h['include'.freeze].to_s.split(?,.freeze)
      result = Renderer[type].render(
        resource,
        href:           href,
        script_name:    env['SCRIPT_NAME'.freeze],
        params:         params,
        include:        include,
        access_control: access_control,
        meta_data:      meta_data,
        accept:         env.fetch('HTTP_ACCEPT'.freeze, 'application/json'.freeze)
      )
      Travis.logger.error("#{self.class}#render: Render failed! type=#{type.inspect} resource=#{resource.inspect} href=#{href} params=#{params.inspect} env=#{env}") if result.nil?

      add_info(result)
    end

    def add_info(payload)
      if warnings.any? && !payload.is_a?(String)
        payload = { :@warnings => [] }.merge!(payload) unless payload.include? :@warnings
        payload[:@warnings].concat(warnings)
      end
      payload
    end

    def method_missing(method, *args)
      return super unless method.to_sym == type.to_sym
      raise ArgumentError, 'wrong number of arguments (1 for 0)'.freeze if args.any?
      resource
    end
  end
end
