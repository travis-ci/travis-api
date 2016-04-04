module Travis::API::V3
  class Services::Overview::Branches < Service

    def run!
      model = Models::Overview.new(find(:repository))
      model.branches
    end
  end
end
