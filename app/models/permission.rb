class Permission < ApplicationRecord
  belongs_to :user
  belongs_to :repository

  scope :admin_access, -> { where(admin: true) }
  scope :push_access,  -> { where(admin: false, push: true) }
  scope :pull_access,  -> { where(admin: false, push: false, pull: true) }
end
