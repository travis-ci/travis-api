require 'faraday'
module Service
  module Repository
    class EnableTravis
      def initialize
      end

      def call
        # We were just playing around with this. DO NOT JUDGE ;)
        Faraday.post "https://api-staging.travis-ci.com/repo/1038/enable",
                     {'Authorization' => 'token token_goes_here'},
                     {'Travis-API-Version' => '3'}
      end

    end
  end
end
