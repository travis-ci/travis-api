require 'travis/services/base'

module Travis
  module Services
    class UpdateUser < Base
      register :update_user

      LOCALES = %w(en es fr ja nb nl pl pt-BR ru de) # TODO how to figure these out

      attr_reader :result

      def run
        @result = current_user.update!(attributes) if valid_locale?
        current_user
      end

      def messages
        messages = []
        if result
          messages << { :notice => "Your profile was successfully updated." }
        else
          messages << { :error => 'Your profile could not be updated.' }
        end
        messages
      end

      private

        def attributes
          params.slice(:locale)
        end

        def valid_locale?
          LOCALES.include?(params[:locale])
        end
    end
  end
end
