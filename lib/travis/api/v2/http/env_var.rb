module Travis
  module Api
    module V2
      module Http
        class EnvVar < Travis::Api::Serializer
          attributes :id, :name, :value, :public

          def value
            if object.public?
              object.value.decrypt
            end
          end

          def serializable_hash
            hash = super
            hash.delete :value unless object.public?
            hash
          end
        end
      end
    end
  end
end
