require 'set'

module Travis::API::V3
  class ModelRenderer
    REDUNDANT = Object.new
    private_constant :REDUNDANT

    def self.type(type = false)
      @type  = type if type != false
      @type  = name[/[^:]+$/].underscore.to_sym unless defined? @type # allows setting type to nil
      @type
    end

    def self.representation(name, *fields)
      location = caller_locations.first
      fields.each do |field|
        class_eval "def #{field}; @model.#{field}; end", location.path, location.lineno unless method_defined?(field)
        available_attributes << field.to_s
      end
      representations[name] ||= []
      representations[name]  += fields
    end

    @representations = {}
    def self.representations
      @representations ||= superclass.representations.dup
    end

    @hidden_representations = []
    def self.hidden_representations(*representations)
      @hidden_representations ||= superclass.hidden_representations.dup

      if representations.first
        @hidden_representations.push(*representations)
      end

      @hidden_representations
    end

    @available_attributes = Set.new
    def self.available_attributes
      @available_attributes ||= superclass.available_attributes.dup
    end

    def self.render(model, representation = nil, **options)
      new(model, **options).render(representation)
    end

    attr_reader :model, :options, :script_name, :params, :include, :included, :access_control
    attr_writer :href

    def initialize(model, script_name: nil, params: {}, include: [], included: [], access_control: nil, **options)
      @model          = model
      @options        = options
      @params         = params
      @script_name    = script_name
      @include        = include
      @included       = included
      @access_control = access_control || AccessControl::Anonymous.new
    end

    def href
      return @href if defined? @href # allows setting href to nil
      return unless self.class.type and model.respond_to? :attributes
      @href = Renderer.href(self.class.type, model.attributes, script_name: script_name)
    end

    def include?(field)
      field = "#{self.class.type}.#{field}" if field.is_a? Symbol
      include.include?(field)
    end

    def query(type)
      Queries[type].new({}, type, includes: include)
    end

    def representation?(name)
      instance_variable_get(:"@representation") == name
    end

    def representation
      :standard
    end

    def render(representation)
      @representation = representation ||= self.representation

      if included.include? model
        return REDUNDANT unless href
        return { :@href => href }
      end

      result                   = {}
      result[:@type]           = self.class.type if self.class.type
      result[:@href]           = href if href
      result[:@representation] = representation
      fields                   = self.class.representations.fetch(representation)
      nested_included          = included + [model]
      modes                    = {}

      if permissions = access_control.permissions(model) and (representation != :minimal or include? :@permissions)
        result[:@permissions] = permissions.to_h
      end

      if include.any?
        excepted_type = result[:@type].to_s
        fields        = fields.dup
      end

      include.each do |qualified_field|
        raise WrongParams, 'illegal format for include parameter'.freeze unless /\A(?<prefix>\w+)\.(?<field>@?\w+)\Z$/ =~ qualified_field
        next if prefix != excepted_type

        if self.class.available_attributes.include?(field)
          field &&= field.to_sym
          fields << field unless fields.include?(field)
          modes[field] = :standard
        else
          raise WrongParams, 'no field %p to include'.freeze % qualified_field unless result.keys.any? { |k| k.to_s == field.to_s }
        end
      end

      Thread.current[:model_renderer_trace] ||= []

      fields.each do |field|
        next if field == :value && !@model.public?

        Thread.current[:model_renderer_trace] << "#{self.class.name.split('::').last}.#{field}"

        value  = Renderer.render_value(send(field),
                   access_control: access_control,
                   script_name:    script_name,
                   include:        include,
                   included:       nested_included,
                   mode:           modes[field])
        result[field] = value unless value == REDUNDANT

        Thread.current[:model_renderer_trace].pop
      end

      result
    end

    def json_format_time_with_ms(time)
      time.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')
    end

    def self.install_tracer
      ActiveSupport::Notifications.subscribe 'sql.active_record' do |*args|
        event = ActiveSupport::Notifications::Event.new *args
        if event.payload[:cached] || event.payload[:name] == 'CACHE'
          next
        end
        if Thread.current[:model_renderer_trace] && Thread.current[:model_renderer_trace].size > 0
          Thread.current[:model_renderer_trace].each_with_index do |frame, i|
            puts ('  ' * (i + 1)) + frame
          end
          puts
        end
      end
    end
  end
end
