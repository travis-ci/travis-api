module Travis::API::V3
  # copy-pasted from Travis::API::V3::Model
  # in order to be able to change the inheritance to
  # Travis::LogsModel, so that postgres connections
  # can be shared between api v2 and v3
  class LogsModel < Travis::LogsModel
    include Extensions::BelongsTo
    self.abstract_class = true

    def self.===(other)
      super or (self == Model and other.class.parent == Models)
    end
  end
end
