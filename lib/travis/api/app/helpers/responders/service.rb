module Travis::Api::App::Helpers::Responders
  class Service < Base
    def apply?
      resource.respond_to?(:run)
    end

    def apply
      # TODO add caching headers depending on the resource
      data = result
      halt 404 if data.nil?
      flash.concat(data.messages) if resource.respond_to?(:messages)
      data
    end

    private

      # Services potentially return all sorts of things
      # If it's a string, true or false we'll wrap it into a hash.
      # If it's an active record instance or scope we just pass it on
      # so it can be processed by the json responder.
      # If it's nil we also pass it but immediately yield not_found.
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

