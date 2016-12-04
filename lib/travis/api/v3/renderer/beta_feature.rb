module Travis::API::V3
  class Renderer::BetaFeature < Renderer::ModelRenderer
    representation :standard, :id, :name, :description, :enabled, :feedback_url
    representation :staff_only, :standard, :staff_only
  end
end
