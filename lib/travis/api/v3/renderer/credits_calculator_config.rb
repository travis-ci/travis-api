module Travis::API::V3
  class Renderer::CreditsCalculatorConfig < ModelRenderer
    representation(:standard, :users, :minutes, :os, :instance_size)
  end
end
