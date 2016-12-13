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

    def to_h
      { 'ssh_key' => attributes.slice(:description, :value).stringify_keys }
    end

    def valid_pem?
      value.decrypt && OpenSSL::PKey::RSA.new(value.decrypt)
      true
    rescue OpenSSL::PKey::RSAError
      false
    end
  end
end
