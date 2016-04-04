module Travis::API::V3
  class Services::Overview::Streak < Service

    def run!
        model = Models::Overview.new(find(:repository))
        model.streak
    end
  end
end
