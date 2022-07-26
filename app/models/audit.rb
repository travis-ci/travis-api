class Audit < ApplicationRecord
  belongs_to :owner, polymorphic: true
  belongs_to :source, polymorphic: true
end
