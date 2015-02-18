module Travis::API::V3
  class Renderer::ModelRenderer
    PRIMITIVE = [String, Symbol, Numeric, true, false, nil]
    private_constant :PRIMITIVE

    def self.type(type = nil)
      @type = type if type
      @type = name[/[^:]+$/].underscore.to_sym unless defined? @type # allows setting type to nil
      @type
    end

    def self.representation(name, *fields)
      fields.each { |field| class_eval "def #{field}; @model.#{field}; end" unless method_defined?(field) }
      representations[name] = fields
    end

    def self.representations
      @representations ||= {}
    end

    def self.render(model, representation = :standard, **options)
      new(model, **options).render(representation)
    end

    attr_reader :model, :options, :script_name
    attr_writer :href

    def initialize(model, script_name: nil, **options)
      @model       = model
      @options     = options
      @script_name = script_name
    end

    def href
      return @href if defined? @href # allows setting href to nil
      return unless self.class.type and model.respond_to? :id and model.id
      @href = Renderer.href(self.class.type, script_name: script_name, id: model.id)
    end

    def render(representation)
      result         = {}
      result[:@type] = self.class.type if self.class.type
      result[:@href] = href if href
      fields         = self.class.representations.fetch(representation)

      fields.each { |field| result[field] = render_value(send(field)) }
      result
    end

    def render_model(model, type: model.class.name.to_sym, mode: :minimal, **options)
      Renderer[type].render(model, mode, script_name: script_name, **options)
    end

    def render_value(value)
      case value
      when Hash          then value.map { |k, v| [k, render_value(v)] }.to_h
      when Array         then value.map { |v   | render_value(v)      }
      when *PRIMITIVE    then value
      when Time          then value.strftime('%Y-%m-%dT%H:%M:%SZ')
      when Travis::Model then render_model(value)
      else raise ArgumentError, 'cannot render %p (%p)' % [value.class, value]
      end
    end
  end
end
