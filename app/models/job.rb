class Job < ActiveRecord::Base

  self.inheritance_column = :_type_disabled

  belongs_to :repository
  belongs_to :owner, polymorphic: true
end
