module Services
  module Repository
    class SetHookUrl < Struct.new(:repository, :config, :hook_link)
      def call
        gh.patch(hook_link, config: config)
      end

      private

      def gh
        GH.with(token: repository.find_admin.github_oauth_token)
      end
    end
  end
end
