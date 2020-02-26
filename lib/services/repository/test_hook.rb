module Services
  module Repository
    class TestHook
      include Travis::VCS

      attr_reader :repository

      def initialize(repository)
        @repository = repository
      end

      def call
        vcs.post("/repos/#{repository.id}/hook/test")
      end
    end
  end
end
