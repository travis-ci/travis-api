module Travis::API::V3
  class Models::Token < Model
    belongs_to        :user
    validates         :token, presence: true
    serialize         :token, Travis::Settings::EncryptedColumn.new(disable: true)
    before_validation :generate_token, on: :create

    def abc
      puts '--------------druga-----------------------'
    end

    protected

    def generate_token
      self.token = SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')
    end
  end
end
