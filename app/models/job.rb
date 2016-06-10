class Job < ActiveRecord::Base
  scope :not_finished, -> {where(state: %w[started received queued created])}

  self.inheritance_column = :_type_disabled

  belongs_to :repository
  belongs_to :owner, polymorphic: true
end
