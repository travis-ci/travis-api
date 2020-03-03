require 'json'

module Travis::API::V3
  module Extensions
    module Preferences
      module ClassMethods
        def has_preferences(klass, column: :preferences, method_name: :preferences)
          define_method method_name do
            # Try to fix setting nil attributes
            data = self[column] if column.is_a?(Hash)
            data = JSON.parse(self[column]) if column.is_a?(String)
            klass.new(self[data]).tap { |prefs| prefs.sync(self, data) }
          end
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    end
  end
end
