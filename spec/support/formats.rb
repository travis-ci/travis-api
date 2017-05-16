module Support
  module Formats
    def json_response
      response = respond_to?(:last_response) ? last_response : self.response
      ActiveSupport::JSON.decode(response.body)
    end

    def xml_response
      response = respond_to?(:last_response) ? last_response : self.response
      ActiveSupport::XmlMini.parse(response.body)
    end

    def json_for_http(object, options = {})
      normalize_json(Travis::Renderer.json(object, options))
    end

    # normalizes datetime objects to strings etc. more similar to what the client would see.
    def normalize_json(json)
      json = json.to_json unless json.is_a?(String)
      JSON.parse(json)
    end

    def json_format_time(time)
      time.strftime('%Y-%m-%dT%H:%M:%SZ')
    end
  end
end

