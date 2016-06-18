require 'travis/api/serialize/formats'
require 'travis/api/serialize/v2/http/branches'

module Travis
  module Api
    module Serialize
      module V2
        module Http
          class Branch < Branches
            include Formats

            attr_reader :build, :commit, :options

            def initialize(build, options = {})
              @build   = build
              @commit  = build.commit
              @options = options
            end

            def data
              {
                'branch' => build_data(build),
                'commit' => commit_data(commit)
              }
            end
          end
        end
      end
    end
  end
end
