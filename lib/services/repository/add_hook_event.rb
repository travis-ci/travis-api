module Services
  module Repository
    class AddHookEvent < Struct.new(:repository, :event, :hook_link)
      def call
        gh.patch(hook_link, add_events: [event])
      end

      private

      def gh
        GH.with(token: repository.find_admin.github_oauth_token)
      end
    end
  end
end
