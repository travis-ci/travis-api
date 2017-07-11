module Travis::API::V3
  class Renderer::Request < ModelRenderer
    representation(:minimal,  :id, :state, :result, :message)
    representation(:standard, *representations[:minimal], :repository, :branch_name, :commit, :builds, :owner, :created_at, :event_type)
  end
end
