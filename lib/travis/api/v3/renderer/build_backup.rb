module Travis::API::V3
  class Renderer::BuildBackup < ModelRenderer
    representation(:minimal, :file_name, :created_at)
    representation(:standard, *representations[:minimal])

    def self.render(model, representation = :standard, **options)
      return super unless options[:accept] == 'text/plain'.freeze

      model.content
    end
  end
end
