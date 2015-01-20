module Travis::API::V3
  module Renderer
    extend self

    def [](key)
      return key if key.respond_to? :render
      const_get(key.to_s.camelize)
    end

    def format_date(date)
      date && date.strftime('%Y-%m-%dT%H:%M:%SZ')
    end
  end
end
