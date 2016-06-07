module Travis::API::V3
  class Models::Settings
    attr_reader :repository

    def initialize(repository)
      @repository = repository
    end

    def to_h
      defaults.merge(repository.settings || {})
    end

    def update(settings = {})
      settings = defaults.merge(settings)
      repository.update_attributes(settings: JSON.generate(settings))
    end

    private

      def defaults
        {
          'builds_only_with_travis_yml' => false,
          'build_pushes' => true,
          'build_pull_requests' => true,
          'maximum_number_of_builds' => 0
        }
      end
  end
end
