module Travis::API::V3
  module Renderer
    extend ConstantResolver
    extend self

    def format_date(date)
      date && date.strftime('%Y-%m-%dT%H:%M:%SZ')
    end

    def get_attributes(object, *attributes, **defaults)
      attributes.map { |a| [a, get_attribute(object, a, **defaults)] }.to_h
    end

    def get_attribute(object, attribute, **defaults)
      value = object.public_send(attribute)
      value.nil? ? defaults[attribute] : value
    end
  end
end
