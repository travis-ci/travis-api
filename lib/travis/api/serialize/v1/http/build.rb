require 'travis/api/serialize/v1/http/build/job'

module Travis
  module Api
    module Serialize
      module V1
        module Http
          class Build
            include Formats, Helpers::Legacy

            attr_reader :build, :commit, :request

            def initialize(build, options = {})
              @build = build
              @commit = build.commit
              @request = build.request
            end

            def data
              puts "***DEBUG1:*** #{build.matrix.first.inspect}"
              puts "***DEBUG2:*** #{Job.new(build.matrix.first).inspect}"
              {
                'id' => build.id,
                'repository_id' => build.repository_id,
                'number' => build.number,
                'config' => build.obfuscated_config.stringify_keys,
                'state' => legacy_build_state(build),
                'result' => legacy_build_result(build),
                'status' => legacy_build_result(build),
                'started_at' => format_date(build.started_at),
                'finished_at' => format_date(build.finished_at),
                'duration' => build.duration,
                'commit' => commit.commit,
                'branch' => commit.branch,
                'message' => commit.message,
                'committed_at' => format_date(commit.committed_at),
                'author_name' => commit.author_name,
                'author_email' => commit.author_email,
                'committer_name' => commit.committer_name,
                'committer_email' => commit.committer_email,
                'compare_url' => commit.compare_url,
                'event_type' => build.event_type,
                'matrix' => build.matrix.map { |job| Job.new(job).data },
              }
            end
          end
        end
      end
    end
  end
end
