module Travis::API::V3
  class Renderer::Execution < ModelRenderer
    representation :minimal, :id, :os, :instance_size, :arch, :virtualization_type, :queue, :job_id,
                   :repository_id, :owner_id, :owner_type, :plan_id, :sender_id, :credits_consumed, :started_at,
                   :finished_at, :created_at, :updated_at, :repository, :sender
    representation :standard, *representations[:minimal]

    def repository
      repo = Repository.find(model.repository_id)
      Renderer::Repository.new(repo).render(:standard)
    end

    def sender
      user = User.find(model.sender_id)
      Renderer::User.new(user).render(:standard)
    end
  end
end
