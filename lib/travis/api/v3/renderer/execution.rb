module Travis::API::V3
  class Renderer::Execution < ModelRenderer
    representation :minimal, :id, :os, :instance_size, :arch, :virtualization_type, :queue, :job_id,
                   :repository_id, :owner_id, :owner_type, :plan_id, :sender_id, :credits_consumed, :started_at,
                   :finished_at, :created_at, :updated_at
    representation :standard, *representations[:minimal]
  end
end
