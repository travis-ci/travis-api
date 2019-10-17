module Travis::API::V3
  module Renderer::Lint
    extend self

    AVAILABLE_ATTRIBUTES = [:warnings]
    WARNING = /\[(alert|error|warn)\]/

    def available_attributes
      AVAILABLE_ATTRIBUTES
    end

    def render(msgs, **)
      {
        '@type': 'lint'.freeze,
        warnings: warnings(msgs)
      }
    end

    def warnings(msgs)
      msgs = msgs.select { |msg| WARNING =~ msg }
      msgs.map { |msg| { key: [], message: msg } }
    end
  end
end
