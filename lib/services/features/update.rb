module Services
  module Features
    class Update
      def initialize(owner)
        @owner = owner
      end

      def call(features)
        ::Features.for(@owner).each do |key, value|
          value = value ? "1" : "0"
          next if value == features[key]
          if features[key] == "0"
            ::Features.deactivate_owner(key, @owner)
          else
            ::Features.activate_owner(key, @owner)
          end
        end
      end
    end
  end
end
