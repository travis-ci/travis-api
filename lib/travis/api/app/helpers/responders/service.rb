module Travis::Api::App::Helpers::Responders
  class Service < Base
    def apply?
      resource.respond_to?(:run)
    end

    def apply
      # TODO add caching headers depending on the resource
      result = resource.run || {}
      flash.concat(resource.messages) if resource.respond_to?(:messages)
      result
    end
  end
end

