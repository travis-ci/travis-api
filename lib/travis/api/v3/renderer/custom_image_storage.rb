module Travis::API::V3
  class Renderer::CustomImageStorage < ModelRenderer
    representation :minimal, :id, :owner_id, :owner_type, :current_aggregated_storage, :created_at, :updated_at, :end_date
    representation :standard, *representations[:minimal]
  end
end
