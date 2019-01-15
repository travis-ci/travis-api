module Travis::API::V3
  class Renderer::Plan < ModelRenderer
    representation(:standard, :id, :name, :builds, :price, :currency, :annual)
    representation(:minimal, :id, :name, :builds, :price, :currency, :annual)
  end
end
