require 'travis/api/app'

class Travis::Api::App
  module Extensions
    # Keeps track of subclasses. Used for endpoint and middleware detection.
    # This will prevent garbage collection of subclasses.
    module SubclassTracker
      def direct_subclasses
        @direct_subclasses ||= []
      end

      # List of "leaf" subclasses (ie subclasses without subclasses).
      def subclasses
        return [self] if direct_subclasses.empty?
        direct_subclasses.map(&:subclasses).flatten.uniq
      end

      def inherited(subclass)
        super
        subclass.set app_file: caller_files.first
        direct_subclasses << subclass
      end
    end
  end
end
