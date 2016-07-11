class Build < ActiveRecord::Base
  include StateDisplay
  include ConfigDisplay

  belongs_to :owner,    polymorphic: true
  belongs_to :repository
  belongs_to :commit
  belongs_to :request
  has_many   :jobs,     as: :source

  serialize :config
end
