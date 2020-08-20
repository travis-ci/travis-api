module Travis::API::V3
  class Renderer::V2Subscription < ModelRenderer
    representation(:standard, :id, :plan, :addons, :status, :source, :owner, :billing_info, :credit_card_info, :payment_intent, :created_at)

    def billing_info
      Renderer.render_model(model.billing_info, mode: :standard) unless model.billing_info.nil?
    end

    def credit_card_info
      Renderer.render_model(model.credit_card_info, mode: :standard) unless model.credit_card_info.nil?
    end

    def plan
      Renderer.render_model(model.plan, mode: :standard) unless model.plan.nil?
    end

    def addons
      Renderer.render_model(model.addons, mode: :standard) unless model.addons.nil?
    end

    def payment_intent
      Renderer.render_model(model.payment_intent, mode: :standard) unless model.payment_intent.nil?
    end
  end
end
