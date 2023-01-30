module Travis::API::V3
  class Models::CustomKey < Model
    belongs_to :owner, polymorphic: true

    serialize :private_key, Travis::Model::EncryptedColumn.new

    validates_each :private_key do |record, attr, private_key|
      record.errors.add(attr, :missing_attr, message: 'missing_attr') if private_key.blank?
      record.errors.add(attr, :invalid_pem, message: 'invalid_pem') unless record.valid_pem?
    end

    def save_key!(owner_type, owner_id, name, description, private_key, added_by)
      self.owner_type = owner_type
      self.owner_id = owner_id
      self.private_key = private_key
      self.name = name
      self.description = description
      self.added_by = added_by

      if self.valid?
        self.fingerprint = calculate_fingerprint(private_key)
        self.public_key = OpenSSL::PKey::RSA.new(private_key).public_key.to_s

        self.save!
      end

      self
    end

    def valid_pem?
      private_key && OpenSSL::PKey::RSA.new(private_key)
      true
    rescue OpenSSL::PKey::RSAError
      false
    end

    private

    def calculate_fingerprint(source)
      rsa_key = OpenSSL::PKey::RSA.new(source)
      public_ssh_rsa = "\x00\x00\x00\x07ssh-rsa" + rsa_key.e.to_s(0) + rsa_key.n.to_s(0)
      OpenSSL::Digest::MD5.new(public_ssh_rsa).hexdigest.scan(/../).join(':')
    end
  end
end
