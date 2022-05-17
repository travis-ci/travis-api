module Travis::API::V3
  class Models::Message < Model
    self.inheritance_column = :none

    belongs_to :subject, polymorphic: true

    scope :ordered, -> do
      order(Arel.sql(%Q{
        CASE
        WHEN level = 'alert' THEN '0'
        WHEN level = 'error' THEN '1'
        WHEN level = 'warn' THEN '2'
        WHEN level = 'info' THEN '3'
        WHEN level IS NULL THEN '4'
        END
      }.strip))
    end
  end
end
