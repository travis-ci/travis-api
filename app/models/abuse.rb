class Abuse < ApplicationRecord
  belongs_to :user

  LEVEL_OFFENDER  = 0
  LEVEL_FISHY     = 1
  LEVEL_NOT_FISHY = 2
end
