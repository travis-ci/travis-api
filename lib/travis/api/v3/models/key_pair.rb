module Travis::API::V3
  class Models::KeyPair < Travis::Settings::Model
    include Models::JsonSync, Models::Fingerprint

    attribute :description, String
    attribute :value, Travis::Settings::EncryptedValue
    attribute :repository_id, Integer

    validates_each :value do |record, attr, value|
      record.errors.add(attr, :missing_attr) if value.blank?
      record.errors.add(attr, :invalid_pem) unless record.valid_pem?
    end

    def fingerprint_source
      value.decrypt
    end

    def public_key
      return unless value.decrypt
      OpenSSL::PKey::RSA.new(value.decrypt).public_key.to_s
    rescue OpenSSL::PKey::RSAError
      nil
    end

    def to_h
      { 'ssh_key' => attributes.slice(:description, :value, :repository_id).stringify_keys }
    end

    def valid_pem?
      value.decrypt && OpenSSL::PKey::RSA.new(value.decrypt)
      true
    rescue OpenSSL::PKey::RSAError
      false
    end

    def update(attributes = {})
      super
      return false unless valid?
      self.tap { |kp| kp.sync! }
    end

    def delete(repository)
      repository.settings = repository.settings.tap { |setting| setting.delete("ssh_key")}.to_json
      repository.save!
    end

    def repository
      V3::Models::Repository.find(repository_id)
    end
  end
end
