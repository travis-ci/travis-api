module Travis::API::V3
  class Permissions::Generic
    def self.access_rights
      @access_rights ||= begin
        rights = superclass.respond_to?(:access_rights) ? superclass.access_rights.dup : []
        public_instance_methods(false) do |method|
          next unless method.to_s =~ /^([^_].+)\?$/
          rights << $1.to_sym
        end
      end
    end

    # for any public method defined with a question mark in the end, it defines a method with an
    # exclamation mark that will raise an InsufficientAccess error if the question mark version
    # returns false
    def self.method_added(method_name)
      super

      return unless public_method_defined?(method_name)
      return unless method_name.to_s =~ /^([^_].+)\?$/

      permission = $1
      type       = name[/[^:]+$/].underscore

      class_eval <<-RUBY
        def #{permission}!
          return self if #{permission}?
          payload = {
            resource_type: "#{type}".freeze,
            permission:    "#{permission}".freeze
          }
          payload[:#{type}] = object if read?
          raise InsufficientAccess.new('operation requires #{permission} access to #{type}', payload)
        end
      RUBY
    end

    attr_accessor :access_control, :object

    def initialize(access_control, object)
      @access_control = access_control
      @object         = object
    end

    def read?
      access_control.visible? object
    end

    private

    def write?
      access_control.writable? object
    end
  end
end
