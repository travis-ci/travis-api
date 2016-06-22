class Build < ActiveRecord::Base
  belongs_to :repository
  belongs_to :commit
  belongs_to :request
end
