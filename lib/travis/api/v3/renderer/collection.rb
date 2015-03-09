module Travis::API::V3
  module Renderer::Collection
    extend self

    def render(collection_type, entry_type, entries, href: nil, script_name: nil, include: [], included: [], **)
      entries &&= entries.map { |entry| Renderer[entry_type].render(entry, script_name: script_name, include: include, included: included) }
      Renderer.clear(:@type => collection_type, :@href => href).merge(collection_type => entries)
    end
  end
end
