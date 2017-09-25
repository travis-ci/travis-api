class Trial < ActiveRecord::Base
  belongs_to :owner, polymorphic: true
  has_many :trial_allowances
end
