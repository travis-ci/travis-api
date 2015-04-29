module Travis::API::V3
  class Permissions::Repository < Permissions::Generic
    def create_request?
      write?
    end
  end
end
