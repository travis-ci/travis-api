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
    sup = super
    if sup.is_a? String
      sup = YAML.load(super)
    end
    @settings ||= sup || {}
  end

  def has_custom_ssh_key?
    !settings["ssh_key"].nil?
  end

  def slug
    @slug ||= "#{owner_name}/#{name}"
  end

  def url_slug
    @url_slug ||= CGI.escape(slug)
  end
end
