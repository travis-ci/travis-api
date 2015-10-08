require 'travis/api/v3/renderer/model_renderer'

module Travis::API::V3
  class Renderer::Build < Renderer::ModelRenderer
    representation(:minimal,  :id, :number, :state, :duration, :event_type, :previous_state, :started_at, :finished_at)
    representation(:standard, *representations[:minimal], :repository, :branch, :commit, :jobs)

    def jobs
      return model.jobs if include_full_jobs?
      model.job_ids.map { |id| job(id) }
    end

    private def include_full_jobs?
      return true if include? 'build.job'.freeze
      return true if include.any?  { |i| i.start_with? 'job.'.freeze }
      return true if included.any? { |i| i.is_a? Models::Job and i.source_id == model.id }
    end

    private def job(id)
      {
        "@type"           => "job",
        :@href            => Renderer.href(:job, script_name: script_name, id: id),
        "@representation" => "minimal",
        "id"              => id
      }
    end
  end
end
