class Repository < ActiveRecord::Base
  has_many :jobs
  has_many :permissions
  has_many :users,   through:     :permissions
  has_many :builds

  belongs_to :owner, polymorphic: true

  def slug
    @slug ||= "#{owner_name}/#{name}"
  end

  def permissions_sorted
    @permissions_sorted ||= begin
      permissions_sorted = { admin: [], push: [], pull: [] }
      permissions.includes(:user).each do |p|
        next permissions_sorted[:admin] << p.user if p.admin?
        next permissions_sorted[:push]  << p.user if p.push?
        next permissions_sorted[:pull]  << p.user if p.pull?
      end
      permissions_sorted
    end
  end
end
