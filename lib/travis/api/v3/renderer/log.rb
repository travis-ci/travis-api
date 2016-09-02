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
      unsorted_content = {}
      log.log_parts.each do |log_part|
        unsorted_content[log_part.number] = log_part.content
      end
      sorted_content = Hash[unsorted_content.sort]
      text = ""
      sorted_content.each_value do |value|
        text << value + "\n"
      end
      text
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
