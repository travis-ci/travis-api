module Travis::API::V3
  class Renderer::ModelRenderer
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
      return unless self.class.type and model.respond_to? :attributes
      @href = Renderer.href(self.class.type, model.attributes, script_name: script_name)
    end

    def render(representation)
      result         = {}
      result[:@type] = self.class.type if self.class.type
      result[:@href] = href if href
      fields         = self.class.representations.fetch(representation)

      fields.each { |field| result[field] = Renderer.render_value(send(field), script_name: script_name) }
      result
    end
  end
end
