class Repository < ActiveRecord::Base
  has_many :jobs
  has_many :permissions
  has_many :users,   through:     :permissions
  has_many :builds

  belongs_to :owner, polymorphic: true

  def slug
    @slug ||= "#{owner_name}/#{name}"
  end
end
