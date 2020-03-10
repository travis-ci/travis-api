module Services
  module Report
    class InvoiceReport
      attr_reader :from, :to, :type

      def initialize(from, to, type)
        @from = from
        @to = to
        @type = type
      end

      def call
        CSV.generate(headers: true) do |csv|
          csv_data.each do |itesm|
            csv << itesm
          end
        end
      end

      def csv_data
        invoice_type = @type == "refund" ? "&type=refunds" : ""
        binding.pry
        request = connection.get("/report?from=#{@from}&to=#{@to}#{invoice_type}")
        CSV.parse( request.body.gsub(/[\r\t]/, ''), col_sep: ',')
      end

      def connection
        @connection ||= Faraday.new(url: billing_url) do |conn|
          conn.token_auth(billing_auth_key)
          conn.request :json
          conn.response :json, content_type: 'application/json'
          conn.adapter Faraday.default_adapter
        end
      end

      def billing_auth_key
        travis_config.billing.auth_key || raise(ConfigurationError, 'No billing auth key configured')
      end

      def billing_url
        travis_config.billing.url || raise(ConfigurationError, 'No billing url configured')
      end

      def travis_config
        TravisConfig.load
      end
    end
  end
end
