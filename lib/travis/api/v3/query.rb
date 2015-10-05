module Travis::API::V3
  class Query
    @@sidekiq_cache = Tool::ThreadLocal.new

    # generate from eval to avoid additional string allocations on every params access
    @@params_accessor = <<-RUBY
      attr_writer :%<method_name>s

      def %<method_name>s
        return @%<method_name>s if defined? @%<method_name>s
        return @%<method_name>s = @params['%<prefix>s.%<name>s'.freeze]            if @params.include? '%<prefix>s.%<name>s'.freeze
        return @%<method_name>s = @params['%<prefix>s'.freeze]['%<name>s'.freeze]  if @params.include? '%<prefix>s'.freeze and @params['%<prefix>s'.freeze].is_a? Hash
        return @%<method_name>s = @params['%<name>s'.freeze]                       if (@params['@type'.freeze] || @main_type) == '%<prefix>s'.freeze
        return @%<method_name>s = @params['%<name>s'.freeze]                       if %<check_type>p and (@params['@type'.freeze] || @main_type) == '%<type>s'.freeze
        @%<method_name>s = nil
      end

      def %<method_name>s!
        %<method_name>s or raise WrongParams, 'missing %<prefix>s.%<name>s'.freeze
      end
    RUBY

    def self.params(*list, prefix: nil, method_name: nil)
      type       = name[/[^:]+$/].underscore
      prefix   ||= type.to_s
      check_type = method_name.nil? and type != prefix
      list.each do |entry|
        class_eval(@@params_accessor % {
          name:        entry,
          prefix:      prefix,
          type:        type,
          method_name: method_name || entry,
          check_type:  check_type
        })
      end
    end

    attr_reader :params, :main_type

    def initialize(params, main_type, includes: nil)
      @params    = params
      @main_type = main_type.to_s
      @includes  = includes
    end

    def perform_async(identifier, *args)
      class_name, queue = @@sidekiq_cache[identifier] ||= [
        "Travis::Sidekiq::#{identifier.to_s.camelcase}".freeze,
        identifier.to_s.pluralize.freeze
      ]

      ::Sidekiq::Client.push('queue'.freeze => queue, 'class'.freeze => class_name, 'args'.freeze => args)
    end

    def includes?(key)
      @includes ||= @params['include'.freeze].to_s.split(?,.freeze)
      key = key.to_s if key.is_a? Symbol

      if key.is_a? String
        key.include?(?.) ? @includes.include?(key) : @includes.any? { |k| k.start_with? key }
      else
        @includes.any? { |k| key === k }
      end
    end

    def bool(value)
      return false if value == 'false'.freeze
      !!value
    end

    def list(value)
      value.split(?,.freeze)
    end

    def user_condition(value)
      case value
      when String       then { login: value    }
      when Integer      then { id:    value    }
      when Models::User then { id:    value.id }
      else raise WrongParams
      end
    end
  end
end
