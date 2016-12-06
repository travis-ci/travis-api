module Travis::API::V3
  module Renderer::Log
    extend self

    def render(log, **options)
      text?(options) ? text(log) : json(log, **options)
    end

    private

    def text?(options)
      options[:accept] == 'text/plain'.freeze
    end

    def text(log)
      log.log_parts.map(&:content).join("\n")
    end

    def json(log, **options)
      Json.new(log, **options).render(:standard)
    end

    class Json < Renderer::ModelRenderer
      type :log
      representation :standard, :id, :content, :log_parts
    end
  end
end
