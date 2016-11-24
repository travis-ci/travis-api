module Travis::API::V3
  class Renderer::SshKey < Renderer::ModelRenderer
    representation :standard, :id, :public_key, :fingerprint
  end
end
