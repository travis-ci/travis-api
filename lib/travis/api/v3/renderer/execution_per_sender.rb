module Travis::API::V3
  class Renderer::ExecutionPerSender < ModelRenderer
    representation :minimal, :credits_consumed, :minutes_consumed, :sender_id, :sender
    representation :standard, *representations[:minimal]
  end
end
