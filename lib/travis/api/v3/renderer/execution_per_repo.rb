module Travis::API::V3
  class Renderer::ExecutionPerRepo < ModelRenderer
    representation :minimal, :repository_id, :os, :credits_consumed, :minutes_consumed, :repository
    representation :standard, *representations[:minimal]
  end
end
