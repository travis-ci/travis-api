module Travis
  module Api
    module V2
      module Http
        class SslKey
          attr_reader :key

          def initialize(key, options = {})
            @key = key
          end

          def fingerprint
            PrivateKey.new(key.private_key).fingerprint
          end

          def data
            {
              'key' => key.public_key,
              'fingerprint' => fingerprint
            }
          end
        end
      end
    end
  end
end

