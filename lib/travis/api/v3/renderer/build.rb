module Travis::API::V3
  class Renderer::Build < ModelRenderer
    representation(:minimal,  :id, :number, :state, :duration, :event_type, :previous_state, :pull_request_title, :pull_request_number, :started_at, :finished_at, :private)
    representation(:standard, *representations[:minimal], :repository, :branch, :tag, :commit, :jobs, :stages, :created_by, :updated_at)
    representation(:active, *representations[:standard])
    representation(:log_complete, :log_complete)

    hidden_representations(:active)
    hidden_representations(:log_complete)

    def self.available_attributes
      super + ['request']
    end

    def request
      # no filtering here, we assume that request.private == request.build.private
      Renderer.render_model(model.request, mode: :minimal)
    end

    def jobs
      # no filtering here, we assume that job.private == job.build.private
      return model.active_jobs if include_full_jobs? && representation?(:active)
      return model.jobs if include_full_jobs?
      return model.job_ids.map { |id| job(id) } unless representation?(:active)
      model.active_jobs.map{ |j| job(j.id) }
    end

    def created_by
     return nil unless creator = model.created_by
     return creator if include?('build.created_by')
     {
       '@type' => model.sender_type.downcase,
       '@href' => created_by_href(creator),
       '@representation' => 'minimal'.freeze,
       'id' => creator.id,
       'login' => creator.login
     }
    end

    def updated_at
      json_format_time_with_ms(model.updated_at)
    end

    private def created_by_href(creator)
      case creator
      when V3::Models::Organization then Renderer.href(:organization, script_name: script_name, id: creator.id)
      when V3::Models::User         then Renderer.href(:user, script_name: script_name, id: creator.id)
      end
    end

    private def include_full_jobs?
      return true if include?('build.jobs'.freeze)
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
