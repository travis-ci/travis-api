require 'travis/api/app'

class Travis::Api::App
  # Superclass for HTTP endpoints. Takes care of prefixing.
  class Endpoint < Responder
    set(:prefix) { "/" << name[/[^:]+$/].underscore }
    set disable_root_endpoint: false
    register :scoping

    before { content_type :json }
    error(ActiveRecord::RecordNotFound, Sinatra::NotFound) { not_found }
    not_found { content_type =~ /json/ ? { 'file' => 'not found' } : 'file not found' }

    private

      def service(key)
        const = Travis.services[key] || raise("no service registered for #{key}")
        const.new(respond_to?(:current_user) ? current_user : nil)
      end
  end
end
