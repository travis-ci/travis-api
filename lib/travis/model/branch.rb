require 'travis/model'

class Branch < Travis::Model
  belongs_to :repository
  belongs_to :last_build, class_name: 'Build'
end
