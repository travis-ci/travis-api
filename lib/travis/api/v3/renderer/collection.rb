
module Travis::API::V3
  module Renderer::Collection
    extend self

    def render(collection_type, entry_type, entries, **additional)
      entries &&= entries.map { |entry| Renderer[entry_type].render(entry) }
      { :@type => collection_type, collection_type => entries, **additional }
    end
  end
end
