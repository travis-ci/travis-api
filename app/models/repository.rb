class Repository < ApplicationRecord
  has_many :jobs
  has_many :permissions
  has_many :users,      through: :permissions
  has_many :builds
  has_many :commits
  has_many :requests
  has_many :branches
  has_many :broadcasts, as:      :recipient

  belongs_to :owner, polymorphic: true
  belongs_to :last_build, class_name: 'Build'

  scope :by_slug,             -> (slug) { without_invalidated.where(owner_name: slug.split('/').first, name: slug.split('/').last).order('id DESC') }
  scope :without_invalidated, -> { where(invalidated_at: nil) }

  serialize :settings

  def binary_settings
    %w[builds_only_with_travis_yml build_pushes build_pull_requests]
  end

  def integer_settings
    %w[maximum_number_of_builds timeout_hard_limit timeout_log_silence api_builds_rate_limit]
  end

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
