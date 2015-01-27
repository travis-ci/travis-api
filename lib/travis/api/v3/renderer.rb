module Travis::API::V3
  module Renderer
    extend ConstantResolver
    extend self

    def format_date(date)
      date && date.strftime('%Y-%m-%dT%H:%M:%SZ')
    end
  end
end
