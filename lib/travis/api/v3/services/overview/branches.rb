module Travis::API::V3
  class Services::Overview::Branches < Service

    def run!
      find(:repository).overview.branches
    end
  end
end
