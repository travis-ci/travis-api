module Travis::API::V3
  class Query
    @@sidekiq_queue = {}

    def self.sidekiq_queue(identifier)
      @@sidekiq_queue[identifier] ||= [
        "Travis::Sidekiq::#{identifier.to_s.camelcase}".freeze,
        identifier.to_s.pluralize.freeze
      ]
    end

    def self.setup_sidekiq(identifier, queue: nil, class_name: nil)
      sidekiq_queue(identifier)[0] = class_name if class_name
      sidekiq_queue(identifier)[1] = queue      if queue
    end

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

    @@prefixed_params_accessor = <<-RUBY
      def %<prefix>s_params
        @%<prefix>s ||= begin
          params = @params.select { |key, _| key.start_with?('%<prefix>s.'.freeze) }
          Hash[params.map { |key, value| [key.split('.'.freeze).last, value] }]
        end
      end
    RUBY

    def self.type
      name[/[^:]+$/].underscore
    end

    def self.experimental_params(*list, prefix: nil, method_name: nil)
      @experimental_params ||= []

      list.each do |entry|
        @experimental_params << [prefix, entry].compact.map(&:to_s).join('.')
        @experimental_params << entry.to_s
      end

      params(*list, prefix: prefix, method_name: method_name)

      @experimental_params
    end

    def self.get_experimental_params
      @experimental_params || []
    end

    def self.params(*list, prefix: nil, method_name: nil)
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
      class_eval(@@prefixed_params_accessor % { prefix: prefix })
    end

    def self.prefix(input)
      return input if input.is_a? String
      "#{type}.#{input}"
    end

    def self.sortable_by(*params, **mapping)
      params.each  { |param|      sort_by[param.to_s] = prefix(param) }
      mapping.each { |key, value| sort_by[key.to_s]   = prefix(value) }
    end

    def self.prevent_sortable_join(*fields)
      dont_join.push(*fields.map(&:to_s))
    end

    @dont_join = []
    def self.dont_join
      @dont_join ||= superclass.dont_join.dup
    end

    @experimental_sortable_by = []
    def self.experimental_sortable_by(*fields)
      @experimental_sortable_by ||= []

      if fields.first
        @experimental_sortable_by.push(*fields.map(&:to_s))
      end

      @experimental_sortable_by
    end

    def self.sort_condition(condition)
      if condition.is_a? Hash
        condition = condition.map { |e| e.map { |v| prefix(v) }.join(" = ".freeze) }.join(" and ".freeze)
      end
      "(case when #{prefix(condition)} then 1 else 2 end)"
    end

    def self.sortable?
      !sort_by.empty?
    end

    @sort_by = {}
    def self.sort_by
      @sort_by ||= superclass.sort_by.dup
    end

    @default_sort = ""
    def self.default_sort(value = nil)
      @default_sort   = value.to_s if value
      @default_sort ||= superclass.default_sort
    end

    attr_reader :params, :main_type

    def initialize(params, main_type, includes: nil, service: nil)
      @params    = params
      @main_type = main_type.to_s
      @includes  = includes
      @service   = service

      ActiveRecord::Base.connection.enable_query_cache! unless Travis.env == 'test'
    end

    def warn(*args)
      return unless @service
      @service.warn(*args)
    end

    def ignored_value(param, value, reason: nil, **info)
      message = reason ? "query value #{value} for #{param} #{reason}, ignored" : "query value #{value} for #{param} ignored"
      warn(message, warning_type: :ignored_value, parameter: param, value: value, **info)
    end

    def perform_async(identifier, *args)
      class_name, queue = Query.sidekiq_queue(identifier)
      ::Sidekiq::Client.push('queue'.freeze => queue, 'class'.freeze => class_name, 'args'.freeze => args.map! {|arg| arg.to_json})
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

    def sort(collection, **options)
      return collection unless sort_by = params["sort_by".freeze] || self.class.default_sort and not sort_by.empty?
      first = true
      list(sort_by).each do |field_with_order|
        field, order = field_with_order.split(?:.freeze, 2)
        order      ||= "asc".freeze
        if sort_by? field, order
          collection = sort_by(collection, field, order: order, first: first, **options)
          first      = false
        else
          ignored_value("sort_by".freeze, field_with_order, reason: "not a valid sort mode".freeze)
        end
      end
      collection
    end

    def sort_by?(field, order)
      return false unless order == "asc".freeze or order == "desc".freeze
      self.class.sort_by.include?(field)
    end

    def sort_by(collection, field, order: nil, first: false, sql: nil, **)
      raise ArgumentError, 'cannot sort by that' unless sort_by?(field, order)
      actual = sql || self.class.sort_by.fetch(field)
      line   = add_order(actual, order)

      if sort_join?(collection, actual)
        collection = collection.joins(actual.to_sym)
      elsif actual != field and sort_join?(collection, field)
        collection = collection.joins(field.to_sym)
      end

      first ? collection.reorder(Arel.sql(line)) : collection.order(Arel.sql(line))
    end

    def sort_join?(collection, field)
      return if self.class.dont_join.include?(field)
      !collection.reflect_on_association(field.to_sym).nil?
    end

    def sort_condition(*args)
      self.class.sort_condition(*args)
    end

    def quote(value)
      ActiveRecord::Base.connection.quote(value)
    end

    def user_condition(value)
      case value
      when String       then { login: value    }
      when Integer      then { id:    value    }
      when Models::User then { id:    value.id }
      else raise WrongParams
      end
    end

    def add_order(field, order)
      order = order.upcase
      if field =~ /%{order}/
        field % { order: order }
      else
        "#{field} #{order}"
      end
    end

    def set_custom_timeout(timeout_in_seconds)
      ActiveRecord::Base.connection.execute "SET statement_timeout = '#{timeout_in_seconds}s';"
    end

    def host_timeout
      return extended_timeout if slow_hosts.any? { |sh| host && host.match?(sh) }
      default_timeout
    end

    def host
      @service.instance_variable_get(:@env)["HTTP_ORIGIN"]
    end

    def slow_hosts
      (ENV['SLOW_HOSTS'] || "").split(',')
    end

    def default_timeout
      Travis.config.db.max_statement_timeout_in_seconds
    end

    def extended_timeout
      Travis.config.db.slow_host_max_statement_timeout_in_seconds
    end
  end
end
