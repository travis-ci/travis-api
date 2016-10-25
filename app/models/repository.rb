class Repository < ApplicationRecord
  has_many :jobs
  has_many :permissions
  has_many :users,      through: :permissions
  has_many :builds
  has_many :commits
  has_many :requests
  has_many :branches
  has_many :broadcasts, as:      :recipient
  has_many :caches

  belongs_to :owner, polymorphic: true
  belongs_to :last_build, class_name: 'Build'

  scope :by_slug,             -> (slug) { without_invalidated.where(owner_name: slug.split('/').first, name: slug.split('/').last).order('id DESC') }
  scope :without_invalidated, -> { where(invalidated_at: nil) }

  serialize :settings

  def find_admin
    permissions.admin_access.first.try(:user)
  end

  def permissions_sorted
    @permissions_sorted ||=
    {
      admin: permissions.admin_access.includes(:user).map(&:user),
      push: permissions.push_access.includes(:user).map(&:user),
      pull: permissions.pull_access.includes(:user).map(&:user)
    }
  end

  def settings
    @settings ||= super || {}
  end

  def slug
    @slug ||= "#{owner_name}/#{name}"
  end
end
