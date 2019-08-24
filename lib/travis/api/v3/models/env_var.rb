module Travis::API::V3
  class Models::EnvVar < Travis::Settings::Model
    attribute :id, Integer
    attribute :name, String
    attribute :value, Travis::Settings::EncryptedValue
    attribute :public, Boolean
    attribute :branch, String
    attribute :repository_id, Integer

    validates :name, presence: true
    validate :check_duplicates

    def repository
      @repository ||= Models::Repository.find(repository_id)
    end

    private

    def check_duplicates
      others = repository.env_vars.select { |ev| ev.id != id }
      errors.add(:base, :duplicate_resource) if others.find { |ev| ev.name == name && ev.branch == branch }
    end
  end
end
