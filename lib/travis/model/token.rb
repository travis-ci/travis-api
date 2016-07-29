require 'securerandom'
require 'travis/model'

# Tokens used for authenticating requests from Github.
#
# Users can have one or many tokens (even though the current UI only allows for
# one) that they need use on their service hooks. This gives us some security
# that people cannot throw random repositories at Travis CI.
class Token < Travis::Model
  belongs_to :user

  validate :token, :presence => true

  before_validation :generate_token, on: :create

  attr_accessible # nothing is changable

  serialize :token, Travis::Model::EncryptedColumn.new(disable: true)

  protected

    def generate_token
      self.token = SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')
    end
end
