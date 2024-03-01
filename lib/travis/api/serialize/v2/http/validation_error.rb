module Travis
  module Api
    module Serialize
      module V2
        module Http
          class ValidationError
            attr_reader :resource

            def initialize(resource, _options = {})
              @resource = resource
              current_class_name = resource.class.name
              resource.class.define_singleton_method(:name) do
                current_class_name || 'ValidationError'
              end
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
              case error_code.to_s
              when /blank/
                'missing_field'
              when /is not a number/
                'not_a_number'
              else
                error_code.to_s
              end
            end
          end
        end
      end
    end
  end
end
