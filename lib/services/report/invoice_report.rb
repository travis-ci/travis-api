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
        client = Services::BillingClient.new
        client.csv_import(@from, @to, @type )
      end
    end
  end
end
