require 'travis/model'

class Email < Travis::Model
  belongs_to :user
end
