module Travis::API::V3
  class Renderer::UserBetaFeature < ModelRenderer
    representation :standard, :id, :name, :description, :enabled, :feedback_url

    type           :beta_feature

    def id
      model.beta_feature.id
    end
  end
end
