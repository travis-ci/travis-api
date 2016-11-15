module Services
  module Repository
    class TestHook < Struct.new(:repository, :href)
      def call
        gh.post(href, {})
      end

      private

      def gh
        GH.with(token: repository.find_admin.github_oauth_token)
      end
    end
  end
end
