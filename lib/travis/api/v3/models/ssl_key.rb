require 'openssl'

module Travis::API::V3
  class Models::SslKey < Model
    include Models::Fingerprint

    belongs_to :repository

    serialize :private_key, Travis::Settings::EncryptedColumn.new

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

    def fingerprint_source
      public_key
    end

    def encoded_public_key
      key = build_key.public_key
      ['ssh-rsa ', "\0\0\0\assh-rsa#{sized_bytes(key.e)}#{sized_bytes(key.n)}"].pack('a*m').gsub("\n", '')
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
end
