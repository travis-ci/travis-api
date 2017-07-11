module Travis::API::V3
  class Renderer::KeyPair < ModelRenderer
    representation :standard, :description, :public_key, :fingerprint
    representation :minimal, *representations[:standard]

    def self.available_attributes
      [*super, :value]
    end

    def href
      Renderer.href(:key_pair,
        :"repository.id" => model.repository_id,
        :"script_name" => script_name
      )
    end
  end
end
