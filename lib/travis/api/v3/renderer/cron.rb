module Travis::API::V3
  class Renderer::Cron < ModelRenderer
    representation(:minimal,  :id)
    representation(:standard, :id, :repository, :branch, :interval, :dont_run_if_recent_build_exists, :last_run, :next_run, :created_at,
        :active)

    def repository
      model.branch.repository
    end

  end
end
