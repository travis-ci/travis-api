class Broadcast < ApplicationRecord
  EXPIRY_TIME = 14.days

  belongs_to :recipient, polymorphic: true

  validates :message, presence: true

  scope :active,         -> { where('created_at >= ? AND (expired IS NULL OR expired <> ?)', EXPIRY_TIME.ago, true).order('id DESC') }
  scope :recent_expired, -> { where('created_at >= ? AND expired = ?', EXPIRY_TIME.ago, true).order('id DESC') }
  scope :inactive,       -> { where('created_at < ? OR (expired = ?)', EXPIRY_TIME.ago, true).order('id DESC') }

  scope :for_user, -> (user) do
    where(<<-SQL, 'Organization', user.organization_ids, 'User', user.id, 'Repository', user.permitted_repository_ids).order('id DESC')
      recipient_type IS NULL OR
      recipient_type = ? AND recipient_id IN(?) OR
      recipient_type = ? AND recipient_id = ? OR
      recipient_type = ? AND recipient_id IN (?)
    SQL
  end

  scope :for_repo, -> (repository) do
    where(<<-SQL, 'Repository', repository.id, repository.owner_type, repository.owner_id).order('id DESC')
      recipient_type IS NULL OR
      recipient_type = ? AND recipient_id = ? OR
      recipient_type = ? AND recipient_id = ?
    SQL
  end

  scope :for_org, -> (organization) do
    where(<<-SQL, 'Organization', organization.id, 'Repository', organization.repository_ids).order('id DESC')
      recipient_type IS NULL OR
      recipient_type = ? AND recipient_id = ? OR
      recipient_type = ? AND recipient_id IN (?)
    SQL
  end

  def self.for(object)
    case object
    when ::User then for_user(object)
    when ::Repository then for_repo(object)
    when ::Organization then for_org(object)
    else where('recipient_type IS NULL OR recipient_type = ? AND recipient_id = ?', object.class, object.id)
    end
  end

  def active?
    !expired? && created_at >= EXPIRY_TIME.ago
  end

  def explicit_expired?
    expired? && created_at >= EXPIRY_TIME.ago
  end

  def inactive?
    created_at < EXPIRY_TIME.ago
  end
end
