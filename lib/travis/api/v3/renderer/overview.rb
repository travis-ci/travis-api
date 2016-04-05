require 'set'
module Travis::API::V3
  class Renderer::Overview < Renderer::ModelRenderer
    type :overview

    attributes = Models::Overview.constants.inject([]) do |acc, struct|
      acc + Models::Overview.const_get(struct).new.to_h.keys
    end
    representation(:standard, *attributes.uniq)

    def initialize(model, href: nil, **options)
      super
      @href = href
    end

    def model_fields(representation)
      model.to_h.keys
    end
  end
end
