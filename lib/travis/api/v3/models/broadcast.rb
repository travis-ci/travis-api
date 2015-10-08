module Travis::API::V3
  class Models::Broadcast < Model
    EXPIRY_TIME = 14.days

    belongs_to :recipient, polymorphic: true
    scope :active,   -> { where('created_at >= ? AND (expired IS NULL OR expired <> ?)', EXPIRY_TIME.ago, true) }
    scope :inactive, -> { where('created_at < ? OR (expired = ?)', EXPIRY_TIME.ago, true) }

    def active?
      return false if expired?
      created_at >= EXPIRY_TIME.ago
    end
  end
end
