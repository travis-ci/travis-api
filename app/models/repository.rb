class Repository < ActiveRecord::Base
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

  def slug
    @slug ||= "#{owner_name}/#{name}"
  end

  def permissions_sorted
    @permissions_sorted ||=
    {
      admin: permissions.admin_access.includes(user: :subscription).map(&:user),
      push: permissions.push_access.includes(user: :subscription).map(&:user),
      pull: permissions.pull_access.includes(user: :subscription).map(&:user)
    }
  end
end
