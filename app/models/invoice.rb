class Invoice < ActiveRecord::Base
  belongs_to :subscription

  serialize :object, Hash

  def amount_due
    object['amount_due']
  end
end
