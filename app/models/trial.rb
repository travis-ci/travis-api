class Trial < ActiveRecord::Base
  belongs_to :owner, polymorphic: true
  has_many :trial_allowances

  scope :underway, -> { where(status: %w{new started ended}) } #'ended' added due to possibility to add trials to expired license (feature was requested )
end