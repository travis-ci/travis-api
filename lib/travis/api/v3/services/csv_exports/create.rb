module Travis::API::V3
  module Services::CsvExports
    class Create < Service
      params :report_type, :recipient_email, :expires_in, prefix: :csv_export

      def run!
        owner = query(:owner).find
        raise NotFound, "Owner not found" unless owner

        csv_export_data = get_csv_export_data
        enqueue_csv_export(owner, csv_export_data)

        recipient_email = csv_export_data['recipient_email']

        response = OpenStruct.new(
          status: 202,
          message: "CSV export job enqueued. You will receive an email at #{recipient_email} when it's ready.",
          owner_id: owner.id,
          owner_type: owner.class.name
        )

        result(response)
      end

      private

      def get_csv_export_data
        input_json = @env['travis.input.json'] if @env
        input_json&.dig('csv_export') || {}
      end

      def enqueue_csv_export(owner, csv_export_data)
        payload = {
          'owner_id' => owner.id,
          'owner_type' => owner.class.name,
          'report_type' => csv_export_data['report_type'],
          'recipient_email' => csv_export_data['recipient_email'],
          'expires_in' => csv_export_data['expires_in']
        }

        Sidekiq::Client.push(
          'queue' => 'billing',
          'class' => 'Travis::Billing::Worker',
          'args' => [
            nil,
            'Travis::Billing::Services::Executions::CsvExport',
            'perform',
            payload
          ].map(&:to_json)
        )

        Travis.logger.info "CSV export job enqueued with payload: #{payload}"
      end
    end
  end
end
