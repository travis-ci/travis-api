module Travis::API::V3
  class Service
    DEFAULT_PARAMS = [ "include".freeze, "@type".freeze ]
    private_constant :DEFAULT_PARAMS

    def self.result_type(type = nil)
      @result_type   = type if type
      @result_type ||= parent.result_type if parent and parent.respond_to? :result_type
      raise 'result type not set' unless defined? @result_type
      @result_type
    end

    def self.filter_params(params)
      wanted = self.params
      params.select { |key| wanted.include? key }
    end

    def self.params(*list, prefix: nil)
      @params ||= superclass.respond_to?(:params) ? superclass.params.dup : DEFAULT_PARAMS
      list.each do |entry|
        @params << entry.to_s
        @params << "#{prefix || result_type}.#{entry}" if entry.is_a? Symbol
      end
      @params
    end

    def self.accepted_params
      self.params.select { |p| p =~ /#{result_type}\./.freeze }
    end

    def self.paginate(**options)
      params("limit".freeze, "offset".freeze)
      params("sort_by".freeze) if query_factory.sortable?
      @paginator = Paginator.new(**options)
    end

    def self.paginator
      @paginator ||= nil
    end

    def self.paginate?
      !!@paginator if defined? @paginator
    end

    def self.query_factory
      Queries[result_type]
    end

    attr_accessor :access_control, :params, :request_body

    def initialize(access_control, params, request_body)
      @access_control = access_control
      @params         = params
      @queries        = {}
      @github         = {}
      @request_body   = request_body
    end

    def query(type = result_type)
      @queries[type] ||= Queries[type].new(params, result_type, service: self)
    end

    def github(user = nil)
      @github[user] ||= GitHub.new(user)
    end

    def find(type = result_type, *args)
      not_found(true,  type) unless object = query(type).find(*args)
      not_found(false, type) unless access_control.visible? object
      object
    end

    def check_login_and_find(*args)
      raise LoginRequired unless access_control.full_access_or_logged_in?
      find(*args) or raise NotFound
    end

    def not_found(actually_not_found = false, type = nil)
      type, actually_not_found = actually_not_found, false if actually_not_found.is_a? Symbol
      error = actually_not_found ? EntityMissing : NotFound
      raise(error, type || result_type)
    end

    def run!
      not_implemented
    end

    def result_type
      self.class.result_type
    end

    def result(*args)
      Result.new(access_control, *args)
    end

    def head(*args)
      Result::Head.new(access_control, *args)
    end

    def deleted
      head result_type, nil, status: 204
    end

    def run
      not_found unless result = run!
      $stderr.puts "The class is: #{result.class}"
      result = result(result_type, result) unless result.class == Result
      result = paginate(result) if self.class.paginate?
      apply_warnings(result)
      result
    end

    def warnings
      @warnings ||= []
    end

    def warn(*args)
      warnings << args
    end

    def apply_warnings(result)
      warnings.each { |args| result.warn(*args) }
    end

    def paginate(result)
      self.class.paginator.paginate(result,
        limit:          params['limit'.freeze],
        offset:         params['offset'.freeze],
        access_control: access_control)
    end

    def params_for?(prefix)
      return true if params['@type'.freeze] == prefix
      return true if params[prefix].is_a? Hash
      params.keys.any? { |key| key.start_with? "#{prefix}." }
    end

    def accepted(**payload)
      payload[:resource_type] ||= result_type
      result(:accepted, payload, status: 202)
    end

    def not_implemented
      raise NotImplemented
    end
  end
end
