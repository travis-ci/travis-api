module Travis::API::V3
  class Service
    def self.required_params
      @required_params ||= []
    end

    def self.params(*list, optional: false, prefix: nil)
      @params ||= []
      list.each do |param|
        method = param = param.to_s
        param = "#{prefix}.#{method}" if prefix
        define_method(method) { params[param] }
        required_params << param unless optional
        @params << param
      end
      @params
    end

    attr_accessor :access_control, :params

    def initialize(access_control, params)
      @access_control = access_control
      @params         = params
    end

    def required_params?
      required_params.all? { |param| params.include? param }
    end

    def required_params
      self.class.required_params
    end
  end
end
