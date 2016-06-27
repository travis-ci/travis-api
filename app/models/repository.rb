class Repository < ActiveRecord::Base
  has_many :jobs
  has_many :permissions
  has_many :users,   through:     :permissions
  has_many :builds
  has_many :commits
  has_many :requests
  has_many :branches

  belongs_to :owner, polymorphic: true

  def slug
    @slug ||= "#{owner_name}/#{name}"
  end

  def permissions_sorted
    @permissions_sorted ||= gather_permissions
  end

  def gather_permissions
    {
      admin: permissions.admin_access.includes(:user).map(&:user),
      push: permissions.push_access.includes(:user).map(&:user),
      pull: permissions.pull_access.includes(:user).map(&:user)
    }
  end
end
