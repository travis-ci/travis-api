module Travis::API::V3
  class Renderer::Request < ModelRenderer
    representation(:minimal,  :id)
    representation(:standard, :id, :repository, :branch_name, :commit, :owner, :created_at, :result, :message, :event_type)
  end
end
