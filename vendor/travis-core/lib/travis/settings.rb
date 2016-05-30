require 'coercible'
require 'travis/overwritable_method_definitions'
require 'travis/settings/collection'
require 'travis/settings/model'
require 'travis/settings/model_extensions'

module Travis
  class Settings
    include Travis::OverwritableMethodDefinitions
    include Virtus.model
    include ActiveModel::Validations
    include Travis::Settings::ModelExtensions

    def on_save(&block)
      @on_save = block
      self
    end

    def merge(hash)
      hash.each { |k, v|
        set(k, v) unless collection?(k) || model?(k)
      }
    end

    def obfuscated
      to_hash
    end

    def save
      if valid?
        @on_save.call
      end
    end

    def to_json
      to_hash.to_json
    end

    def to_hash
      result = super

      result.each do |key, value|
        if value.respond_to?(:to_hash)
          result[key] = value.to_hash
        end
      end

      result
    end
  end

  module DefaultSettings
    def initialize(*)
      super

      freeze
    end

    def merge(*)
      raise "merge is not supported on default settings"
    end

    def set(key, value)
      raise "setting values is not supported on default settings"
    end
  end
end
