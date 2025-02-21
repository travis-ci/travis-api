module Travis::API::V3
  class Models::AccountEnvVar < Model
    belongs_to :owner, polymorphic: true

    serialize :value, Travis::Model::EncryptedColumn.new
    define_callbacks :after_change
    set_callback :after_change, :after, :save_audit

    def save_account_env_var!(account_env_var)
      account_env_var.save if account_env_var.valid?
      @changes = {
        created:
          "name: #{account_env_var.name}, public: #{account_env_var.public}"
      }
      run_callbacks :after_change
      account_env_var
    end

    def delete(account_env_var)
      @changes =  {
        deleted:
          "name: #{account_env_var.name}, public: #{account_env_var.public}"
      }
      account_env_var.destroy
      run_callbacks :after_change
    end

    def changes
      @changes
    end

    private

    def save_audit
      Travis::API::V3::Models::Audit.create!(
        owner: self.owner,
        change_source: 'travis-api',
        source: self,
        source_changes: {
          account_env_var: self.changes
        }
      )
      @changes = {}
    end
  end
end
