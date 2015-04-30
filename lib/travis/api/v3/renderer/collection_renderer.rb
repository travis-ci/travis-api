module Travis::API::V3
  class Renderer::CollectionRenderer
    def self.render(list, **options)
      new(list, **options).render
    end

    def self.available_attributes
      @available_attributes ||= Set.new
    end

    def self.type(value)
      define_method(:type) { value }
    end

    def self.collection_key(value)
      define_method(:collection_key) { value }
      available_attributes << value
    end

    def initialize(list, href: nil, included: [], **options)
      @href     = href
      @options  = options
      @list     = list
      @included = included
    end

    def render
      result                 = { :"@type" => type }
      result[:@href]         = @href if @href
      included               = @included.dup
      result[collection_key] = @list.map do |entry|
        rendered = render_entry(entry, included: included, mode: :standard, **@options)
        included << entry
        rendered
      end
      result
    end

    def render_entry(entry, **options)
      Renderer.render_value(entry, **options)
    end
  end
end
