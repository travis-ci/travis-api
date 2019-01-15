module Travis::API::V3
  class Models::Preference < Struct.new(:name, :value, :parent)
    def public?
      true
    end
  end
end
