module Travis::API::V3
  class Models::Settings
    attr_reader :repository

    def initialize(repository)
      @repository = repository
    end

    def to_h
      repository.user_settings.to_hash
    end

    def update(settings = {})
      repository.settings = repository.user_settings.update(settings).to_json
      repository.settings_will_change!
      repository.save!
    end
  end
end
