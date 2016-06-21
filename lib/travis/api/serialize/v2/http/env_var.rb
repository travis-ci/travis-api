module Travis
  module Api
    module Serialize
      module V2
        module Http
          class EnvVar < Travis::Api::Serialize::ObjectSerializer
            attributes :id, :name, :value, :public, :repository_id

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
end
