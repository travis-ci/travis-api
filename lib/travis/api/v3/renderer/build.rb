module Travis::API::V3
  class Renderer::Build < ModelRenderer
    representation(:minimal,  :id, :number, :state, :duration, :event_type, :previous_state, :pull_request_title, :pull_request_number, :started_at, :finished_at)
    representation(:standard, *representations[:minimal], :repository, :branch, :commit, :jobs, :stages, :created_by)
    representation(:active, *representations[:standard])

    hidden_representations(:active)

    def jobs
      return model.active_jobs if include_full_jobs? && representation?(:active)
      return model.jobs if include_full_jobs?
      return model.job_ids.map { |id| job(id) } unless representation?(:active)
      model.active_jobs.map{ |j| job(j.id) }
    end

    def created_by
      if creator = model.created_by
        payload = {
          '@type' => model.sender_type.downcase,
          '@href' => created_by_href(creator),
          '@representation' => 'minimal'.freeze,
          'id' => creator.id,
          'login' => creator.login
        }
        payload['avatar_url'] = V3::Renderer::AvatarURL.avatar_url(creator) if include?('created_by.avatar_url')
        payload
      end
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
