require 'travis/api/serialize/v1/webhook/build/finished'

module Travis
  module Api
    module Serialize
      module V1
        module Webhook
          class Build
            attr_reader :build, :commit, :request, :repository, :options

            def initialize(build, options = {})
              @build = build
              @commit = build.commit
              @request = build.request
              @repository = build.repository
              @options = options
            end

            private

            def build_url
              ["https://#{Travis.config.host}", repository.slug, 'builds', build.id].join('/')
            end
          end
        end
      end
    end
  end
end
