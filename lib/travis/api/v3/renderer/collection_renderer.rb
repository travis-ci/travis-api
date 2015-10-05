module Travis::API::V3
  class Renderer::CollectionRenderer
    def self.render(list, **options)
      new(list, **options).render
    end

    def self.available_attributes
      @available_attributes ||= Set.new
    end

    def self.representations
      { standard: available_attributes }
    end

    def self.type(value)
      define_method(:type) { value }
    end

    def self.collection_key(value)
      define_method(:collection_key) { value }
      available_attributes << value
    end

    attr_reader :href, :options, :list, :included, :include, :meta_data

    def initialize(list, href: nil, included: [], include: [], meta_data: {}, **options)
      @href      = href
      @options   = options
      @list      = list
      @included  = included
      @include   = include
      @meta_data = meta_data
    end

    def fields
      fields               = { :"@type" => type }
      fields[:@href]       = href if href
      fields[:@representation] = representation
      fields[:@pagination] = pagination_info if meta_data.include? :pagination
      fields
    end

    def pagination_info
      return meta_data[:pagination] unless href
      generator = V3::Paginator::URLGenerator.new(href, **meta_data[:pagination])
      meta_data[:pagination].merge generator.to_h
    end

    def render
      result                 = fields
      included               = self.included.dup
      result[collection_key] = list.map do |entry|
        rendered = render_entry(entry, included: included, include: filtered_include, mode: representation, **options)
        included << entry
        rendered
      end
      result
    end

    def filtered_include
      key = collection_key.to_s
      include.reject { |entry| entry.split(?..freeze, 2).last == key }
    end

    def representation
      :standard
    end

    def render_entry(entry, **options)
      Renderer.render_value(entry, **options)
    end
  end
end
