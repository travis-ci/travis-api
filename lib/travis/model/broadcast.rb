require 'travis/model'

class Broadcast < Travis::Model
  belongs_to :recipient, polymorphic: true

  class << self
    def by_user(user)
      sql = %(
        recipient_type IS NULL OR
        recipient_type = ? AND recipient_id IN(?) OR
        recipient_type = ? AND recipient_id = ? OR
        recipient_type = ? AND recipient_id IN (?)
      )
      active.where(sql, 'Organization', user.organization_ids, 'User', user.id, 'Repository', user.repository_ids)
    end

    def by_repo(repository)
      sql = %(
        recipient_type IS NULL OR
        recipient_type = ? AND recipient_id = ? OR
        recipient_type = ? AND recipient_id = ?
      )
      active.where(sql, 'Repository', repository.id, repository.owner_type, repository.owner_id)
    end

    def active
      where('created_at >= ? AND (expired IS NULL OR expired <> ?)', 14.days.ago, true).order('id DESC')
    end
  end
end
