require 'openssl'

module Travis
  module Api
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
            key = OpenSSL::PKey::RSA.new(value)
            ssh_rsa = "\x00\x00\x00\x07ssh-rsa" + key.e.to_s(0) + key.n.to_s(0)
            OpenSSL::Digest::MD5.new(ssh_rsa).hexdigest.scan(/../).join(':')
          rescue OpenSSL::PKey::RSAError
            nil
          end
        end
      end
    end
  end
end
