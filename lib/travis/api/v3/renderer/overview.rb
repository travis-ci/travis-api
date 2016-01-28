require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Overview < Renderer::CollectionRenderer
    type :overview

    def render
      results = fields
      list.first.each_pair do |k, v|
        results[k] = render_entry(v, mode: representation, **options)
      end
      results
    end
  end
end
