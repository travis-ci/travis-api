require 'openssl'
require 'travis/private_key'

module Travis
  module Api
    module Serialize
      module V2
        module Http
          class SshKey < Travis::Api::Serializer
            attributes :id, :description, :fingerprint

            def id
              object.repository_id
            end

            def fingerprint
              value = object.value.decrypt
              return unless value
              PrivateKey.new(value).fingerprint
            rescue OpenSSL::PKey::RSAError
              nil
            end
          end
        end
      end
    end
  end
end
