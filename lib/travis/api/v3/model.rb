module Travis::API::V3
  class Model < ActiveRecord::Base
    include Extensions::BelongsTo
    self.abstract_class = true

    def self.===(other)
      super or other.class.parent == Models
    end
  end
end
