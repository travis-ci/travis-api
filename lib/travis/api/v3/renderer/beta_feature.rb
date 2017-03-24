module Travis::API::V3
  class Renderer::BetaFeature < Renderer::ModelRenderer
    representation(:standard, :id, :name, :description, :enabled, :feedback_url)

    def id
      return model.beta_feature_id if model.respond_to?(:beta_feature_id)
      model.id
    end
  end
end
