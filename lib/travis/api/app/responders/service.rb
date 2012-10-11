module Travis::Api::App::Responders
  class Service < Base
    def apply?
      resource.respond_to?(:run)
    end

    def apply
      cache_control
      result = normalize(resource.run)
      flash.concat(resource.messages) if result && resource.respond_to?(:messages)
      result
    end

    private

      def cache_control
        if final?
          endpoint.expires 31536000, :public # 1 year
        elsif updated_at?
          endpoint.cache_control :public, :must_revalidate
          endpoint.last_modified resource.updated_at
        end
      end

      def final?
        resource.respond_to?(:final?) && resource.final?
      end

      def updated_at?
        resource.respond_to?(:updated_at) && resource.updated_at
      end

      # Services potentially return all sorts of things
      # If it's a string, true or false we'll wrap it into a hash.
      # If it's an active record or scope we just pass so it can be processed by the json responder.
      # If it's nil we also pass it but yield not_found.
      def normalize(result)
        case result
        when String, true, false
          { result: result }
        else
          result
        end
      end
  end
end
