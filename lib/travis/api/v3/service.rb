module Travis::API::V3
  class Service
    def self.result_type(type = nil)
      @result_type = type if type
      raise 'result type not set' unless defined? @result_type
      @result_type
    end

    attr_accessor :access_control, :params

    def initialize(access_control, params)
      @access_control = access_control
      @params         = params
      @queries        = {}
    end

    def query(type = self.class.result_type)
      @queries[type] ||= Queries[type].new(params)
    end

    def not_found(actually_not_found = false, type = nil)
      type, actually_not_found = actually_not_found, false if actually_not_found.is_a? Symbol
      error = actually_not_found ? EntityMissing : NotFound
      raise(error, type || self.class.result_type)
    end

    def run
      not_found unless result = run!
      result = Result.new(self.class.result_type, result) unless result.is_a? Result
      result
    end
  end
end
