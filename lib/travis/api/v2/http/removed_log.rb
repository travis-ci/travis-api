module Travis
  module Api
    module V2
      module Http
        class RemovedLog < Travis::Api::Serializer
          attributes :id, :job_id, :body, :removed_at, :removed_by

          def body
            object.content
          end

          def removed_by
            object.removed_by.name || object.removed_by.login if object.removed_by
          end

        end
      end
    end
  end
end
