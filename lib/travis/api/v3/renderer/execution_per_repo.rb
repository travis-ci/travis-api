module Travis::API::V3
  class Renderer::ExecutionPerRepo < ModelRenderer
    representation :minimal, :repository_id, :os, :credits_consumed, :minutes_consumed
    representation :standard, *representations[:minimal]
  end
end
