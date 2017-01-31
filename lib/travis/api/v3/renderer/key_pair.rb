module Travis::API::V3
  class Renderer::KeyPair < Renderer::ModelRenderer
    representation :standard, :description, :public_key, :fingerprint

    def href
      Renderer.href(:key_pair,
        :"repository.id" => model.repository_id,
        :"script_name" => script_name
      )
    end
  end
end
