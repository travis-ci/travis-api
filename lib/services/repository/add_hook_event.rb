module Services
  module Repository
    class AddHookEvent < Struct.new(:repository, :event, :hook_link)
      include Travis::GitHub

      def call
        gh.patch(hook_link, add_events: [event])
      end
    end
  end
end
