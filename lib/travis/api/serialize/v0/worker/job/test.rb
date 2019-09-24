module Travis
  module Api
    module Serialize
      module V0
        module Worker
          class Job
            class Test < Job
              include Formats

              def data
                {
                  'type' => 'test',
                  # TODO legacy. remove this once workers respond to a 'job' key
                  'build' => job_data,
                  'job' => job_data,
                  'source' => build_data,
                  'repository' => repository_data,
                  'pull_request' => commit.pull_request? ? pull_request_data : false,
                  'config' => job.decrypted_config,
                  'queue' => job.queue,
                  'uuid' => Travis.uuid,
                  'ssh_key' => ssh_key,
                  'env_vars' => env_vars,
                  'timeouts' => timeouts
                }
              end

              def build_data
                {
                  'id' => build.id,
                  'number' => build.number
                }
              end

              def job_data
                data = {
                  'id' => job.id,
                  'number' => job.number,
                  'commit' => commit.commit,
                  'commit_range' => commit.range,
                  'commit_message' => commit.message,
                  'branch' => commit.branch,
                  'ref' => commit.pull_request? ? commit.ref : nil,
                  'state' => job.state.to_s,
                  'secure_env_enabled' => job.secure_env_enabled?
                }
                data['tag'] = request.tag_name if include_tag_name?
                data['pull_request'] = commit.pull_request? ? commit.pull_request_number : false
                data
              end

              def repository_data
                {
                  'id' => repository.id,
                  'slug' => repository.slug,
                  'github_id' => repository.github_id,
                  'vcs_id' => repository.vcs_id,
                  'vcs_type' => repository.vcs_type,
                  'source_url' => repository.source_url,
                  'api_url' => repository.api_url,
                  'last_build_id' => repository.last_build_id,
                  'last_build_number' => repository.last_build_number,
                  'last_build_started_at' => format_date(repository.last_build_started_at),
                  'last_build_finished_at' => format_date(repository.last_build_finished_at),
                  'last_build_duration' => repository.last_build_duration,
                  'last_build_state' => repository.last_build_state.to_s,
                  'description' => repository.description,
                  'default_branch' => repository.default_branch
                }
              end

              def pull_request_data
                {
                  'number' => commit.pull_request_number,
                  'head_repo' => request.head_repo,
                  'base_repo' => request.base_repo,
                  'head_branch' => request.head_branch,
                  'base_branch' => request.base_branch
                }
              end

              def ssh_key
                nil
              end

              def env_vars
                vars = settings.env_vars
                vars = vars.public unless job.secure_env_enabled?

                vars.map do |var|
                  {
                    'name' => var.name,
                    'value' => var.value.decrypt,
                    'public' => var.public
                  }
                end
              end

              def timeouts
                { 'hard_limit' => timeout(:hard_limit), 'log_silence' => timeout(:log_silence) }
              end

              def timeout(type)
                timeout = settings.send(:"timeout_#{type}")
                timeout = timeout * 60 if timeout # worker handles timeouts in seconds
                timeout
              end

              def include_tag_name?
                Travis.config.include_tag_name_in_worker_payload && request.tag_name.present?
              end

              def settings
                repository.settings
              end
            end
          end
        end
      end
    end
  end
end
