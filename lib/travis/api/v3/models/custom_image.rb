module Travis::API::V3
  class Models::CustomImage < Model
    after_initialize :readonly!
    belongs_to :owner, polymorphic: true
    has_many :custom_image_logs

    scope :available, -> { where(state: 'available') }

    def created_by
      user_id = custom_image_logs.created.first&.sender_id
      return unless user_id

      User.find(user_id)
    end

    def private
      true
    end
  end
end
