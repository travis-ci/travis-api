require 'set'

module Travis::API::V3
  class Renderer::ModelRenderer
    REDUNDANT = Object.new
    private_constant :REDUNDANT

    def self.type(type = false)
      @type  = type if type != false
      @type  = name[/[^:]+$/].underscore.to_sym unless defined? @type # allows setting type to nil
      @type
    end

    def self.representation(name, *fields)
      fields.each do |field|
        class_eval "def #{field}; @model.#{field}; end" unless method_defined?(field)
        available_attributes << field.to_s
      end
      representations[name] = fields
    end

    def self.representations
      @representations ||= {}
    end

    def self.available_attributes
      @available_attributes ||= Set.new
    end

    def self.render(model, representation = :standard, **options)
      new(model, **options).render(representation)
    end

    attr_reader :model, :options, :script_name, :include, :included
    attr_writer :href

    def initialize(model, script_name: nil, include: [], included: [], **options)
      @model       = model
      @options     = options
      @script_name = script_name
      @include     = include
      @included    = included
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

    def render(representation)
      if included.include? model
        return REDUNDANT unless href
        return { :@href => href }
      end

      result          = {}
      result[:@type]  = self.class.type if self.class.type
      result[:@href]  = href if href
      fields          = self.class.representations.fetch(representation)
      nested_included = included + [model]
      modes           = {}

      excepted_type = result[:@type].to_s if include.any?
      include.each do |qualified_field|
        raise WrongParams, 'illegal format for include parameter'.freeze unless /\A(?<prefix>\w+)\.(?<field>\w+)\Z$/ =~ qualified_field
        next if prefix != excepted_type
        raise WrongParams, 'no field %p to include'.freeze % qualified_field unless self.class.available_attributes.include?(field)

        field &&= field.to_sym
        fields << field unless fields.include?(field)
        modes[field] = :standard
      end
  
      fields.each do |field|
        value         = Renderer.render_value(send(field), script_name: script_name, include: include, included: nested_included, mode: modes[field])
        result[field] = value unless value == REDUNDANT
      end

      result
    end
  end
end
