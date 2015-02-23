module Travis::API::V3
  class Model < ActiveRecord::Base
    include Extensions::BelongsTo
    self.abstract_class = true
  end
end
