require 'uri'
require 'closeio'

module Travis::API::V3
  class Services::Lead::Create < Service
    result_type :lead
    params :name, :email, :team_size, :phone, :message, :utm_source

    def run!
      # Validation
      raise WrongParams, 'missing name' unless params['name'] && params['name'].length > 0
      raise WrongParams, 'invalid email' unless params['email'] && params['email'].length > 0 && params['email'].match(URI::MailTo::EMAIL_REGEXP).present?
      raise WrongParams, 'missing message' unless params['message'] && params['message'].length > 0

      # Prep data for request
      name, email, team_size, phone, message, utm_source = params.values_at('name', 'email', 'team_size', 'phone', 'message', 'utm_source')
      phones = []
      phones.push({ type: "office", phone: phone }) unless phone.nil?

      lead_data = {
        name: name,
        'custom.team_size': team_size,
        'custom.utm_source': utm_source || 'Travis API',
        contacts: [{
          name: name,
          emails: [{ type: "office", email: email }],
          phones: phones
        }]
      }

      # Send request
      api_client = Closeio::Client.new(Travis.config.closeio.key)
      lead = api_client.create_lead(lead_data)
      note = api_client.create_note({ lead_id: lead['id'], note: message })

      # Return result
      model = Travis::API::V3::Models::Lead.new(lead)
      result model
    end
  end
end