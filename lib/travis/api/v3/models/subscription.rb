module Travis::API::V3
  class Models::Subscription < Model
    belongs_to :owner, polymorphic: true

    def active?
      valid_to.present? and valid_to >= Time.now
    end

  end
end
