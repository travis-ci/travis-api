module Travis
  module Api
    module V2
      module Http
        class SshKey < Travis::Api::Serializer
          attributes :id, :name
        end
      end
    end
  end
end
