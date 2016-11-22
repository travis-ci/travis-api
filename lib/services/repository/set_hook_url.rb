module Services
  module Repository
    class SetHookUrl < Struct.new(:repository, :config, :hook_link)
      include Travis::GitHub

      def call
        gh.patch(hook_link, config: config)
      end
    end
  end
end
