module Travis::API::V3
  class Models::Token < Model
    belongs_to        :user
    validate          :token, presence: true
    serialize         :token#, Extensions::EncryptedColumn.new(disable: true)
    before_validation :generate_token, on: :create

    protected

    def generate_token
      self.token = "christopher"#SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')
    end
  end
end
