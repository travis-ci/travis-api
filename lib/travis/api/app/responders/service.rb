module Travis::Api::App::Responders
  class Service < Base
    def apply?
      resource.respond_to?(:run)
    end

    def apply
      # TODO add caching headers depending on the resource
      data = result
      flash.concat(data.messages) if data && resource.respond_to?(:messages)
      data
    end

    private

      # Services potentially return all sorts of things
      # If it's a string, true or false we'll wrap it into a hash.
      # If it's an active record or scope we just pass so it can be processed by the json responder.
      # If it's nil we also pass it but yield not_found.
      def result
        case result = resource.run
        when String, true, false
          { result: result }
        else
          result
        end
      end
  end
end

