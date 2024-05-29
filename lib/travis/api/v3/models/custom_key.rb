module Travis::API::V3
  class Models::CustomKey < Model
    belongs_to :owner, polymorphic: true

    serialize :private_key, Travis::Model::EncryptedColumn.new

    validates_each :private_key do |record, attr, private_key|
      record.errors.add(attr, :missing_attr, message: 'missing_attr') if private_key.blank?
      record.errors.add(attr, :invalid_pem, message: 'invalid_pem') unless record.valid_key?
    end

    def save_key!(owner_type, owner_id, name, description, private_key, added_by, public_key = nil)
      self.owner_type = owner_type
      self.owner_id = owner_id
      private_key = "#{private_key}\n" unless private_key.end_with?("\n")
      self.private_key = private_key
      self.name = name
      self.description = description
      self.added_by = added_by
      self.public_key = public_key

      if self.valid?
        self.fingerprint = calculate_fingerprint(private_key, public_key)
        self.public_key = public_key || get_public_key(private_key)

        self.save!
      end

      self
    end

    def get_public_key(key)
      OpenSSL::PKey::RSA.new(key).public_key
    rescue OpenSSL::PKey::RSAError
      begin
        parsed_keys = SSHData::PrivateKey.parse_openssh(key)
        public_key = parsed_keys[0]&.public_key
        return unless public_key

        bytes = if public_key.respond_to?(:public_key_bytes)
                  public_key.public_key_bytes
                elsif public_key.respond_to?(:pk)
                  public_key.pk
                end

        return unless bytes

        "-----BEGIN PUBLIC KEY-----\n#{Base64.encode64(bytes)}\n-----END PUBLIC KEY-----\n"
      rescue SSHData::DecodeError
        begin
          OpenSSL::PKey::EC.new(key)&.public_to_pem
        rescue
        end
      end
    end

    def valid_pem?(priv)
      return unless priv.start_with?('-----BEGIN ') && priv.include?('---END ')

      lines = priv.split("\n").slice(1 .. -2)
      if lines.last.include?('---END')
        lines.pop()
      end
      !!Base64.strict_decode64(lines.join())
    rescue ArgumentError
    end

    def valid_key?
      return valid_pem?(private_key) if public_key

      private_key && OpenSSL::PKey::RSA.new(private_key)
    rescue OpenSSL::PKey::RSAError
      valid_nonrsa?
    end

    def valid_nonrsa?
      SSHData::PrivateKey.parse_openssh(private_key).any?
    rescue SSHData::DecodeError, SSHData::DecryptError
      !!begin
          OpenSSL::PKey::EC.new(private_key, '')
        rescue
        end
    end

    private

    def calculate_fingerprint(source, public_key = nil)
      return OpenSSL::Digest::MD5.new(public_key).hexdigest.scan(/../).join(':') if public_key

      rsa_key = OpenSSL::PKey::RSA.new(source)
      public_ssh_rsa = "\x00\x00\x00\x07ssh-rsa" + rsa_key.e.to_s(0) + rsa_key.n.to_s(0)
      OpenSSL::Digest::MD5.new(public_ssh_rsa).hexdigest.scan(/../).join(':')
    rescue OpenSSL::PKey::RSAError
      OpenSSL::Digest::MD5.new(OpenSSL::PKey::EC.new(source)&.public_to_pem).hexdigest.scan(/../).join(':')
    end
  end
end
