module Services
  module Repository
    class TestHook < Struct.new(:repository, :href)
      include Travis::GitHub

      def call
        gh.post(href, {})
      end
    end
  end
end
