class User < Travis::Resource
  # self.element_name = "user"
  self.collection_name = "user"
  # I don't think this has to match the way API has it exactly but putting this here for now.
  # TODO: Find what/how this needs to be added
  # has_many :memberships,   dependent: :destroy
  # has_many :permissions,   dependent: :destroy
  # has_many :emails,        dependent: :destroy
  # has_many :tokens,        dependent: :destroy
  # has_many :organizations, through:   :memberships
  # has_many :repositories,  as:        :owner
  # has_one  :subscription,  as:        :owner
end