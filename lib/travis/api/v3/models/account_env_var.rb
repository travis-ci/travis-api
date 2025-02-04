module Travis::API::V3
  class Models::AccountEnvVar < Model
    belongs_to :owner, polymorphic: true

    serialize :value, Travis::Model::EncryptedColumn.new

    def save_account_env_var!(owner_type, owner_id, name, value, public)
      self.owner_type = owner_type
      self.owner_id = owner_id
      self.name = name
      self.value = value
      self.public = public

      self.save! if self.valid?

      self
    end
  end
end
