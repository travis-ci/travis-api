module Travis
  module Api
    module Serialize
      module V2
        module Http
          class EnvVar < Travis::Api::Serialize::ObjectSerializer
            attributes :id, :name, :value, :public, :branch, :repository_id

            def value
              if object.public?
                object.value.decrypt
              end
            end

            def serializable_hash(adapter_options)
              hash = super(adapter_options)
              hash.delete :value unless object.public?
              hash
            end
          end
        end
      end
    end
  end
end
