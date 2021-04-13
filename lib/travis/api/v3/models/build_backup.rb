module Travis::API::V3
  class Models::BuildBackup < Model
    attr_accessor :content

    belongs_to :repository
  end
end
