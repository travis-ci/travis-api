module Travis::API::V3
  class Models::Subscription < Model

    def active?
      valid_to.present? and valid_to + 1.day >= Time.now
    end

  end
end
