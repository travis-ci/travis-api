module Travis::API::V3
  class Services::Overview::Branches < Service

    def run!
      find(:repository).branches_overview
    end
  end
end
