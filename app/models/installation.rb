class Installation < ApplicationRecord
  belongs_to :owner,   polymorphic: true
end