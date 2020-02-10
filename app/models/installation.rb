class Installation < ApplicationRecord
  belongs_to :owner,   polymorphic: true

  alias_attribute :vcs_id, :github_id
end
