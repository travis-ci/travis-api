class Invoice < ActiveRecord::Base
  belongs_to :subscription

  serialize :object, Hash
end
