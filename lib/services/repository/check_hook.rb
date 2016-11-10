module Services
  module Repository
    class CheckHook < Struct.new(:repository)
      def call
        gh["/repos/#{repository.slug}/hooks"].detect { |h| h['name'] == 'travis' }
      end

      private

      def gh
        GH.with(token: repository.find_admin.github_oauth_token)
      end
    end
  end
end
