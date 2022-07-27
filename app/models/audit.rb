class Audit < ApplicationRecord
  belongs_to :owner, polymorphic: true
  belongs_to :source, polymorphic: true

  def human_changes
    YAML.dump(source_changes)
  end
end
