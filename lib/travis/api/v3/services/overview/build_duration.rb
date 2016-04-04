module Travis::API::V3
  class Services::Overview::BuildDuration < Service

    def run!
      model = Models::Overview.new(find(:repository))
      model.build_duration
    end
  end
end
