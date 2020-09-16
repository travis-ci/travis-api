module Travis::API::V3
  class Renderer::V2AddonConfig < ModelRenderer
    representation(:standard, :id, :name, :price, :quantity, :type)
    representation(:minimal, :id, :name, :price, :quantity, :type)
  end
end
