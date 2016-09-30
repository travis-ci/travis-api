class Request < ApplicationRecord
  # include Searchable

  belongs_to :owner, polymorphic: true
  belongs_to :commit
  belongs_to :repository
  has_many   :builds

  serialize  :payload

  # def as_indexed_json(options = nil)
  #   self.as_json(only: [:id])
  # end
end
