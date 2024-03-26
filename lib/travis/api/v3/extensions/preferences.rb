require 'active_support/all'

module Travis::API::V3
  module Extensions
    module Preferences
      module ClassMethods
        def has_preferences(klass, column: :preferences, method_name: :preferences)
          define_method method_name do
            klass.new(self[column]).tap { |prefs| prefs.sync(self, column) }
          end
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    end
  end
end
