class TrialAllowance < ActiveRecord::Base
  belongs_to :trial
  belongs_to :creator, polymorphic: true
end
