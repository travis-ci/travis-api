require 'uri'

module Travis::API::V3
  class Services::Lead::Create < Service
    result_type :lead
    params :name, :email, :team_size, :phone, :message

    def run!
      raise WrongParams, 'missing name' unless params['name'] && params['name'].length > 0
      raise WrongParams, 'invalid email' unless params['email'] && params['email'].length > 0 && params['email'].match(URI::MailTo::EMAIL_REGEXP).present?
      raise WrongParams, 'missing message' unless params['message'] && params['message'].length > 0

      lead_data = {}
      lead_data['id'] = 'temp_fake_id'
      lead_data['name'] = params['name']
      lead_data['emails'] = [{ type: "office", email: params['email'] }]

      if params['phone'].nil?
        lead_data['phones'] = []
      else
        lead_data['phones'] = [{ type: "office", phone: params['phone'] }]
      end

      lead = Travis::API::V3::Models::Lead.new(lead_data)

      result lead
    end
  end
end