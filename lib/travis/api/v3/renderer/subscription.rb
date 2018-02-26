module Travis::API::V3
  class Renderer::Subscription < ModelRenderer
    representation(:standard, :id, :valid_to, :first_name, :last_name, :company, :zip_code, :address, :address2, :city, :state, :country, :vat_id, :status, :source, :selected_plan)
  end
end
