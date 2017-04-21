module Travis::API::V3
  class Renderer::Job < ModelRenderer
    representation(:minimal, :id)
    representation(:standard, *representations[:minimal], :number, :state, :started_at, :finished_at, :build, :queue, :repository, :commit, :owner, :stage)
    representation(:active, *representations[:standard])

    hidden_representations(:active)
  end
end
