module Travis
  module Api
    module V2
      module Http
        class EnvVar < Travis::Api::Serializer
          attributes :id, :name, :public
        end
      end
    end
  end
end
