module Travis::API::V3
  class Models::Settings
    DEFAULTS = {
      'builds_only_with_travis_yml' => false,
      'build_pushes' => true,
      'build_pull_requests' => true,
      'maximum_number_of_builds' => 0
    }.freeze

    attr_reader :repository

    def initialize(repository)
      @repository = repository
    end

    def to_h
      DEFAULTS.merge(repository.settings || {})
    end

    def update(settings = {})
      settings = to_h.merge(settings)
      repository.settings.clear
      settings.each { |k, v| repository.settings[k] = v }
      repository.save!
    end
  end
end
