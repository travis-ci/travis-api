module Travis::API::V3
  class Service
    attr_accessor :access_control, :params

    def initialize(access_control, params)
      @access_control = access_control
      @params         = params
      @queries        = {}
    end

    def query(type)
      @queries[type] ||= Queries[type].new(params)
    end
  end
end
