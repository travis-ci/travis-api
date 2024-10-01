module Travis::API::V3
  class Renderer::V2Trial < ModelRenderer
    representation(:standard, :concurrency_limit, :max_builds, :max_jobs_per_build, :status, :builds_triggered, :started_at, :finish_time, :credit_usage, :user_usage)
    representation(:minimal, :concurrency_limit, :max_builds, :max_jobs_per_build, :status, :builds_triggered, :started_at, :finish_time, :credit_usage, :user_usage)

    def credit_usage
      Renderer.render_model(model.credit_usage, mode: :standard) unless model.credit_usage.nil?
    end

    def user_usage
      Renderer.render_model(model.user_usage, mode: :standard) unless model.user_usage.nil?
    end
  end
end
