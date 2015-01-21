require 'rack/utils'

module Travis::API::V3
  class Error < StandardError
    def self.create(default_message = nil, **options)
      options[:default_message] = default_message if default_message
      Class.new(self) { options.each { |key, value| define_singleton_method(key) { value } } }
    end

    def self.status
      500
    end

    def self.type
      @type ||= name[/[^:]+$/].underscore
    end

    def self.template
      '%s'.freeze
    end

    def self.default_message
      @default_message ||= Rack::Utils::HTTP_STATUS_CODES.fetch(status, 'unknown error'.freeze).downcase
    end

    attr_accessor :status, :type, :payload

    def initialize(message = self.class.default_message, status: self.class.status, type: self.class.type, **payload)
      if message.is_a? Symbol
        payload[:resource_type] ||= message
        message = self.class.template % message
      end

      self.status, self.type, self.payload = status, type, payload
      super(message)
    end
  end
end
