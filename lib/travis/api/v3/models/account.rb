module Travis::API::V3
  class Models::Account
    attr_accessor :owner

    def initialize(owner)
      @owner = owner
    end

    def id
      owner.github_id
    end

    def subscription
      owner.subscription if owner.respond_to? :subscription
    end

    def educational?
      return false unless owner.respond_to? :educational
      !!owner.educational
    end

    def subscribed?
      subscription.present? and subscription.active?
    end

    alias_method :educational, :educational?
    alias_method :subscribed,  :subscribed?
  end
end