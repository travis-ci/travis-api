module Travis
  module Api
    module V2
      module Http
        class Caches
          include Formats
          attr_reader :caches, :options

          def initialize(caches, options = {})
            @caches  = caches
            @options = options
          end

          def data
            { 'caches' => caches.map { |cache| cache_data(cache) } }
          end

          private

              def cache_data(cache)
                {
                  'repository_id' => cache.repository.id,
                  'size'          => cache.size,
                  'slug'          => cache.slug,
                  'branch'        => cache.branch,
                  'last_modified' => format_date(cache.last_modified)
                }
              end
        end
      end
    end
  end
end