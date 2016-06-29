class Build < ActiveRecord::Base
  include StateMessages

  belongs_to :owner, polymorphic: true
  belongs_to :repository
  belongs_to :commit
  belongs_to :request
  has_many   :jobs,     as: :source
end
