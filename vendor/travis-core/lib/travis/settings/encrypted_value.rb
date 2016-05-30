require 'virtus'

class Travis::Settings
  class EncryptedValue
    include Virtus.value_object
    attr_reader :value, :key

    values do
      attribute :value, String
    end

    def initialize(value)
      if value.is_a? String
        # a value is set through the accessor, not loaded in jason, we
        # need to encrypt it and put into hash form
        value = { value: encrypt(value) }
      end

      super value
    end

    def to_s
      value
    end

    def to_str
      value
    end

    def to_json(*)
      as_json.to_json
    end

    def as_json(*)
      value
    end

    def to_hash
      value
    end

    def inspect
      "<Settings::EncryptedValue##{object_id}>"
    end

    def key
      Travis.config.encryption.key
    end

    def encrypt(value)
       Travis::Model::EncryptedColumn.new(key: key, use_prefix: false).dump(value)
    end

    def decrypt
      Travis::Model::EncryptedColumn.new(key: key, use_prefix: false).load(value)
    end

    def load(value, additional_attributes = nil)
      self.instance_variable_set('@value', value)
    end
  end
end
