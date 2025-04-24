module Travis::API::V3
  class Renderer::PlanShare < ModelRenderer
    representation(:standard, :plan_id, :donor, :receiver, :shared_by, :created_at, :admin_revoked, :credits_consumed)
    representation(:minimal, :plan_id, :donor, :receiver, :shared_by, :created_at, :admin_revoked, :credits_consumed)
  end
end
