class Abuse < ApplicationRecord
  belongs_to :user

  LEVEL_OFFENDER  = 0
  LEVEL_FISHY     = 1
  LEVEL_NOT_FISHY = 2

  scope :level_offender, -> { where(level: LEVEL_OFFENDER) }
  scope :level_fishy, -> { where(level: LEVEL_FISHY) }
  scope :level_not_fishy, -> { where(level: LEVEL_NOT_FISHY) }
  scope :not_level_not_fishy, -> { where.not(level: LEVEL_NOT_FISHY) }
end
