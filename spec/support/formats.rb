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

    def json_for_pusher(event, object)
      normalize_json(Travis::Event::Handler::Pusher::Payload.new(event, object).to_hash)
    end

    def json_for_webhook(object)
      normalize_json(Travis::Event::Handler::Webhook::Payload.new(object).to_hash)
    end

    def json_for_worker(object, extra = {})
      normalize_json(Travis::Event::Handler::Worker::Payload.new(object).to_hash)
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

