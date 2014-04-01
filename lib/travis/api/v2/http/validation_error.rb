module Travis
  module Api
    module V2
      module Http
        class ValidationError
          attr_reader :resource

          def initialize(resource, options = {})
            @resource = resource
          end

          def data
            response = {
              message: 'Validation failed'
            }
            resource.errors.to_hash.each do |name, errors|
              response['errors'] ||= []
              errors.each do |error_code|
                response['errors'] << { field: name, code: code(error_code) }
              end
            end

            response
          end

          def code(error_code)
            case error_code
            when :blank
              'missing_field'
            else
              error_code.to_s
            end
          end
        end
      end
    end
  end
end

