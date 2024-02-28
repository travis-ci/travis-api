require 'travis/model'

class Email < Travis::Model
  self.table_name = 'emails'
  belongs_to :user
end
