module Travis::API::V3
  class Renderer::ScanResult < ModelRenderer
    representation(:minimal, :id, :created_at, :formatted_content, :issues_found, :job_id, :build_id, :job_number, :build_number, :job_finished_at,
                             :commit_sha, :commit_compare_url, :commit_branch, :build_created_by)
    representation(:standard, *representations[:minimal])

    def build_created_by
      job = Travis::API::V3::Models::Job.find(model.job_id)
      build = Travis::API::V3::Models::Build.find(job.source_id)
      return nil unless creator = build.sender
      {
        '@type' => build.sender_type.downcase,
        '@href' => created_by_href(creator),
        '@representation' => 'minimal'.freeze,
        'id' => creator.id,
        'login' => creator.login
      }
    end

    private def created_by_href(creator)
      case creator
      when V3::Models::Organization then Renderer.href(:organization, script_name: script_name, id: creator.id)
      when V3::Models::User         then Renderer.href(:user, script_name: script_name, id: creator.id)
      end
    end
  end
end
