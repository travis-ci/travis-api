require 'openssl'
require 'base64'
require 'travis/model'

# A Repository has an SSL key pair that is used to encrypt/decrypt sensitive
# data so it can be added to a public `.travis.yml` file (e.g. Campfire
# credentials).
class SslKey < Travis::Model
  self.table_name = 'ssl_keys'
  include Travis::ScopeAccess

  belongs_to :repository

  validates :repository_id, :presence => true, :uniqueness => true
  validates :public_key,    :presence => true
  validates :private_key,   :presence => true

  before_validation :generate_keys, :on => :create

  serialize :private_key, Travis::Model::EncryptedColumn.new

  def encode(string)
    Base64.encode64(encrypt(string)).strip
  end

  def encrypt(string)
    build_key.public_encrypt(string)
  end

  def decrypt(string)
    build_key.private_decrypt(string)
  end

  def generate_keys!
    self.public_key = self.private_key = nil
    generate_keys
  end

  def generate_keys
    unless public_key && private_key
      keys = OpenSSL::PKey::RSA.generate(Travis.config.repository.ssl_key.size)
      self.public_key = keys.public_key.to_s
      self.private_key = keys.to_pem
    end
  end

  def encoded_public_key
    key = build_key.public_key
    ['ssh-rsa ', "\0\0\0\assh-rsa#{sized_bytes(key.e)}#{sized_bytes(key.n)}"].pack('a*m').gsub("\n", '')
  end

  def encoded_private_key
    [private_key].pack('m').strip
  end

  def secure
    Travis::SecureConfig.new(self)
  end

  private

    def build_key
      @build_key ||= OpenSSL::PKey::RSA.new(private_key)
    end

    def sized_bytes(value)
      bytes = to_byte_array(value.to_i)
      [bytes.size, *bytes].pack('NC*')
    end

    def to_byte_array(num, *significant)
      return significant if num.between?(-1, 0) and significant[0][7] == num[7]
      to_byte_array(*num.divmod(256)) + significant
    end
end
