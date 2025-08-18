module Travis::API::V3
  class Renderer::CustomImagesUsage < ModelRenderer
    representation :minimal, :total_usage, :excess_usage, :free_usage, :quantity_limit_free, :quantity_limit_type,
                   :quantity_limit_charge
    representation :standard, *representations[:minimal]
  end
end
