module Travis::API::V3
  class Permissions::Preferences < Permissions::Generic
    def read?
      true
    end

    def write?
      true
    end
  end
end
