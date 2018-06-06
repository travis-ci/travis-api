module Travis::API::V3
  class Permissions::Trial < Permissions::Generic
    def read?
      object.permissions.read?
    end

    def write?
      object.permissions.write?
    end
  end
end
