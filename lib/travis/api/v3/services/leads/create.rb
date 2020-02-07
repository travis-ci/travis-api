require 'uri'
require 'closeio'

module Travis::API::V3
  class Services::Leads::Create < Service
    result_type :leads
    params :name, :email, :team_size, :phone, :message, :referral_source, :utm_fields

    def run!
      # Get params
      name, email, team_size, phone, message, referral_source, utm_fields = params.values_at('name', 'email', 'team_size', 'phone', 'message', 'referral_source', 'utm_fields')
      team_size = team_size.to_i unless team_size.nil?
      name = name.strip unless name.nil?
      message = message.strip unless message.nil?

      # Validation
      raise WrongParams, 'missing name' unless name && name.length > 0
      raise WrongParams, 'invalid email' unless email && email.length > 0 && email.match(URI::MailTo::EMAIL_REGEXP).present?
      raise WrongParams, 'missing message' unless message && message.length > 0
      raise WrongParams, 'invalid team size' if team_size && team_size <= 0

      # Prep data for request
      api_client = Closeio::Client.new(Travis.config.closeio.key, ENV['RACK_ENV'] != 'test')
      custom_fields = api_client.list_custom_fields
      team_size_field = fetch_custom_field(custom_fields, 'team_size')
      referral_source_field = fetch_custom_field(custom_fields, 'referral_source')

      phones = []
      phones.push({ type: "office", phone: phone }) unless phone.nil?

      lead_data = {
        name: name,
        contacts: [{
          name: name,
          emails: [{ type: "office", email: email }],
          phones: phones
        }],
      }

      lead_data["custom.#{team_size_field['id']}"] = team_size if team_size_field && team_size
      lead_data["custom.#{referral_source_field['id']}"] = referral_source || 'Travis API' if referral_source_field

      # Handle UTM fields
      supported_utm_fields = ['utm_source', 'utm_campaign', 'utm_medium', 'utm_term', 'utm_content']
      supported_utm_fields.each do |field_name|
        field = fetch_custom_field(custom_fields, field_name)
        field_data = utm_fields[field_name] if utm_fields
        lead_data["custom.#{field['id']}"] = field_data if field && field_data
      end

      # Send request
      lead = api_client.create_lead(lead_data)
      note = api_client.create_note({ lead_id: lead['id'], note: message })

      # Return result
      model = Travis::API::V3::Models::Leads.new(lead)
      result model
    end

    private

    def fetch_custom_field(custom_fields, field_name)
      custom_fields['data'].find { |field| field['name'] == field_name }
    end
  end
end