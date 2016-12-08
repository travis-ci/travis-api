module Travis::API::V3
  class Renderer::UserBetaFeature < Renderer::ModelRenderer
    representation :standard, :id, :name, :description, :enabled, :feedback_url
    representation :staff_only, :standard, :staff_only

    type           :beta_feature

    def id
      model.beta_feature.id
    end
  end
end
