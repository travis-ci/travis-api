module Travis::API::V3
  class Services::Lead::Create < Service
    result_type :lead
    params :name, :phone

    def run!
      lead_data = {}
      lead_data['id'] = 'temp_fake_id'
      lead_data['name'] = params['name']
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