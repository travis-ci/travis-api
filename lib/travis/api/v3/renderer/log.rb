module Travis::API::V3
  class Renderer::Log < ModelRenderer
    def self.render(model, representation = :standard, **options)
      return super unless options[:accept] == 'text/plain'.freeze
      model.content
    end

    representation(:minimal, :id)
    representation(:standard, *representations[:minimal], :content, :log_parts)
  end
end
