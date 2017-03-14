require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::BetaFeature < Renderer::ModelRenderer
    representation :standard, :id, :name, :description, :enabled, :feedback_url
    representation :staff_only, :standard, :staff_only

    def id
      return model.beta_feature_id if model.respond_to?(:beta_feature_id)
      model.id
    end
  end
end
