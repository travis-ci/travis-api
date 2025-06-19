module Travis::API::V3
  module Services::CsvExports
    class Create < Service
      params :report_type, :recipient_email, :expires_in, prefix: :csv_export

      def run!
        owner = query(:owner).find
        raise NotFound, "Owner not found" unless owner

        enqueue_csv_export(owner)

        input_json = @env['travis.input.json'] if @env
        csv_export_data = input_json&.dig('csv_export') || {}
        recipient_email = csv_export_data['recipient_email']

        response = OpenStruct.new(
          status: 202,
          message: "CSV export job enqueued. You will receive an email at #{recipient_email} when it's ready.",
          owner_id: owner.id
        )

        result(response)
      end

      private

      def enqueue_csv_export(owner)
        input_json = @env['travis.input.json'] if @env
        csv_export_data = input_json&.dig('csv_export') || {}

        payload = {
          'owner_id' => owner.id,
          'report_type' => csv_export_data['report_type'],
          'recipient_email' => csv_export_data['recipient_email'],
          'expires_in' => csv_export_data['expires_in']
        }

        puts " this is the payload: #{payload}"

        Sidekiq::Client.push(
          'queue' => 'hub',
          'class' => 'Travis::Hub::Sidekiq::Worker',
          'args' => ['csv_export:create', payload].map(&:to_json)
        )
      end
    end
  end
end
