module Travis
  module Api
    module Serialize
      module V2
        module Http
          class AccountEnvVar < Travis::Api::Serialize::ObjectSerializer
            attributes :id, :owner_id, :owner_type, :name, :value, :public, :created_at, :updated_at

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
