require 'virtus'
require 'travis/settings/encrypted_value'
require 'travis/settings/model_extensions'

class Travis::Settings
  class Model
    include Virtus.model
    include ActiveModel::Validations
    include ModelExtensions
    include ActiveModel::Serialization

    def attribute?(name)
      attributes.keys.include?(name.to_sym)
    end

    def read_attribute_for_serialization(name)
      self.send(name) if attribute?(name)
    end

    def read_attribute_for_validation(name)
      return unless attribute?(name)

      value = self.send(name)
      value.is_a?(EncryptedValue) ? value.to_s : value
    end

    def update(attributes)
      self.attributes = attributes
    end

    def key
      Travis.config.encryption.key
    end

    def to_json
      to_hash.to_json
    end
  end
end
