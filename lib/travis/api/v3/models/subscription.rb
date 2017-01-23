module Travis::API::V3
  class Models::Subscription < Model

    def active?
      cc_token? and valid_to.present? and valid_to >= Time.now.utc
    end

  end
end
