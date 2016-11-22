module Services
  module Repository
    class CheckHook < Struct.new(:repository)
      include Travis::GitHub

      def call
        gh["/repos/#{repository.slug}/hooks"].detect { |h| h['name'] == 'travis' }
      end
    end
  end
end
