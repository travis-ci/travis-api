require 'json'
require 'faraday'

module Travis::API::V3
  class Queries::Lint < RemoteQuery
    MIME_TYPE = 'application/vnd.travis-ci.configs+json'

    def lint(content)
      response = client.post([config: content, source: 'lint'])
      handle_errors(response)
      body = JSON.parse(response.body)
      body['full_messages']
    end

    def client
      Client.new(config)
    end

    def handle_errors(response)
      case response.status
      when 400 then raise Error, 'bad request'
      when 500 then raise Error, 'travis-yml application error'
      end
    end

    class Client < Struct.new(:config)
      extend Forwardable

      def post(content)
        client.post do |r|
          r.url '/v1/parse'
          r.headers['Content-Type'] = MIME_TYPE
          r.body = JSON.dump(content)
        end
      end

      private

        def client
          @client ||= Faraday.new(config[:url], ssl: ssl) do |client|
            client.request(:authorization, :basic, 'admin', config[:auth_key])
            client.headers['Accept'] = 'application/json'
            client.adapter :net_http
          end
        end

        def ssl
          { ca_path: '/usr/lib/ssl/certs' }
        end

        def config
          super[:yml]
        end
    end
  end
end
