require 'uri'
require 'net/http'
require 'travis_config'

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
          http_request.each do |itesm|
            csv << itesm
          end
        end
      end

      def http_request
        invoice_type = @type == "refund" ? "&type=refunds" : ""
        uri = URI(Services::Billing_v2_authentication.new.billing_url + "/report?from=#{@from}&to=#{@to}" + invoice_type)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri)
        request["Content-Type"] = 'application/x-www-form-urlencoded'
        request["Authorization"] = 'Token token=' + Services::Billing_v2_authentication.new.billing_auth_key
        request = http.request(request)
        CSV.parse( request.read_body.gsub(/[\r\t]/, ''), col_sep: ',')
      end
    end
  end
end
