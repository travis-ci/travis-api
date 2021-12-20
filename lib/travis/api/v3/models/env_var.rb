module Travis::API::V3
  class Models::EnvVar < Travis::Settings::Model
    attribute :id, Integer
    attribute :name, String
    attribute :value, Travis::Settings::EncryptedValue
    attribute :public, Boolean
    attribute :branch, String
    attribute :repository_id, Integer

    validates :name, presence: true
    validates_each :id, :name do |record, attr, value|
      others = record.repository.env_vars.select { |ev| ev.id != record.id }
      record.errors.add(:base, :duplicate_resource) if others.find { |ev| ev.send(attr) == record.send(attr) && ev.send(:branch) == record.send(:branch) }
    end

    def repository
      @repository ||= Models::Repository.find(repository_id)
    end
  end
end
