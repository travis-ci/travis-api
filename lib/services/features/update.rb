module Services
  module Features
    class Update
      include ApplicationHelper

      def initialize(owner, current_user)
        @owner = owner
        @current_user = current_user
      end

      def call(features)
        ::Features.for(@owner).each do |key, value|
          value = value ? "1" : "0"
          next if value == features[key]

          if features[key] == "0"
            ::Features.deactivate_owner(key, @owner)
            Services::EventLogs::Add.new(@current_user, "disabled feature flag #{key} for #{describe(@owner)}").call
          else
            ::Features.activate_owner(key, @owner)
            Services::EventLogs::Add.new(@current_user, "enabled feature flag #{key} for #{describe(@owner)}").call
          end
        end
      end
    end
  end
end
