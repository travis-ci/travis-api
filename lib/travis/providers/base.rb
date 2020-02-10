module Travis
  module Providers
    class Base
      attr_reader :profile

      def initialize(profile)
        @profile = profile
      end

      def profile_link
        raise NotImplementedError
      end
    end
  end
end
