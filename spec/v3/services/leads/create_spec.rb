describe Travis::API::V3::Services::Leads::Create, set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  let(:endpoint) { "/v3/leads" }
  let(:parsed_body) { JSON.load(body) }
  let(:full_options) {{
    "name" => "Test Name",
    "email" => "test@email.example.com",
    "team_size" => "123",
    "phone" => "+1 123-456-7890",
    "message" => "Interested in CI",
    "referral_source" => "Custom Source",
    "utm_fields" => {
      "utm_source" => "Custom UTM source",
      "utm_campaign" => "Custom UTM campaign",
      "utm_medium" => "Custom UTM medium",
      "utm_term" => "Custom UTM term",
      "utm_content" => "Custom UTM content"
    }
  }}
  let(:options) { full_options }
  let(:expected_lead_data) {{
    "@type"           => "leads",
    "@representation" => "standard",
    "id"              => "lead_12345",
    "name"            => options['name'],
    "status_label"    => "Potential",
    "contacts"        => [{
      "display_name" => options['name'],
      "name" => options['name'],
      "phones" => [{ "type" => "office", "phone" => options['phone'] }],
      "emails" => [{ "type" => "office", "email" => options['email'] }]
    }],

    "custom"          => {
      "referral_source" => options['referral_source'],
      "team_size"  => options['team_size'],
      "utm_source" => options['utm_fields']['utm_source'],
      "utm_campaign" => options['utm_fields']['utm_campaign'],
      "utm_medium" => options['utm_fields']['utm_medium'],
      "utm_term" => options['utm_fields']['utm_term'],
      "utm_content" => options['utm_fields']['utm_content']
    }
  }}

  let(:close_url) { "https://api.close.com/api/v1/" }
  let(:close_lead_url) { "#{close_url}lead/" }
  let(:stubbed_response_status) { 200 }
  let(:stubbed_response_body) { JSON.dump(expected_lead_data) }
  let(:stubbed_response_headers) {{ content_type: 'application/json' }}
  let!(:stubbed_request) do
    stub_request(:post, close_lead_url).to_return(
      status: stubbed_response_status,
      body: stubbed_response_body,
      headers: stubbed_response_headers
    )
  end

  let(:close_note_url) { "#{close_url}activity/note/" }
  let!(:stubbed_note_request) do
    stub_request(:post, close_note_url).to_return(
      status: stubbed_response_status,
      body: JSON.dump([{ "note" => options['message'] }]),
      headers: stubbed_response_headers
    )
  end

  let(:close_list_custom_url) { "#{close_url}custom_fields/lead/" }
  let!(:stubbed_list_custom_request) do
    stub_request(:get, close_list_custom_url).to_return(
      status: stubbed_response_status,
      body: JSON.dump({ "data" => [
        { "name" => "team_size", "id" => "23456" },
        { "name" => "referral_source", "id" => "34567" },
      ]}),
      headers: stubbed_response_headers
    )
  end

  subject(:response) { post(endpoint, options, headers) }

  it 'sends a contact request' do
    expect(response.status).to eq(200)
    response_data = JSON.parse(response.body)
    expect(response_data).to eq(expected_lead_data)
  end

  context 'when name is missing' do
    let(:options) {{
      "email" => full_options['email'],
      "team_size" => full_options['team_size'],
      "phone" => full_options['phone'],
      "message" => full_options['message'],
      "referral_source" => full_options['referral_source']
    }}
    let(:expected_lead_data) {{
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "missing name",
    }}

    it 'rejects the request' do
      expect(response.status).to eq(400)
      response_data = JSON.parse(response.body)
      expect(response_data).to eq(expected_lead_data)
      expect(stubbed_request).to_not have_been_made
      expect(stubbed_note_request).to_not have_been_made
    end
  end

  context 'when message is missing' do
    let(:options) {{
      "name" => full_options['name'],
      "email" => full_options['email'],
      "team_size" => full_options['team_size'],
      "phone" => full_options['phone'],
      "referral_source" => full_options['referral_source']
    }}
    let(:expected_lead_data) {{
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "missing message",
    }}

    it 'rejects the request' do
      expect(response.status).to eq(400)
      response_data = JSON.parse(response.body)
      expect(response_data).to eq(expected_lead_data)
      expect(stubbed_request).to_not have_been_made
      expect(stubbed_note_request).to_not have_been_made
    end
  end

  context 'when email is missing' do
    let(:options) {{
      "name" => full_options['name'],
      "team_size" => full_options['team_size'],
      "phone" => full_options['phone'],
      "message" => full_options['message'],
      "referral_source" => full_options['referral_source']
    }}
    let(:expected_lead_data) {{
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "invalid email",
    }}

    it 'rejects the request' do
      expect(response.status).to eq(400)
      response_data = JSON.parse(response.body)
      expect(response_data).to eq(expected_lead_data)
      expect(stubbed_request).to_not have_been_made
      expect(stubbed_note_request).to_not have_been_made
    end
  end

  context 'when email is invalid' do
    let(:options) {{
      "name" => full_options['name'],
      "email" => "incorrect-email",
      "team_size" => full_options['team_size'],
      "phone" => full_options['phone'],
      "message" => full_options['message'],
      "referral_source" => full_options['referral_source']
    }}
    let(:expected_lead_data) {{
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "invalid email",
    }}

    it 'rejects the request' do
      expect(response.status).to eq(400)
      response_data = JSON.parse(response.body)
      expect(response_data).to eq(expected_lead_data)
      expect(stubbed_request).to_not have_been_made
      expect(stubbed_note_request).to_not have_been_made
    end
  end

  context 'when team_size is string' do
    let(:options) {{
      "name" => full_options['name'],
      "email" => full_options['email'],
      "team_size" => 'invalid team size',
      "phone" => full_options['phone'],
      "message" => full_options['message'],
      "referral_source" => full_options['referral_source']
    }}
    let(:expected_lead_data) {{
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "invalid team size",
    }}

    it 'rejects the request' do
      expect(response.status).to eq(400)
      response_data = JSON.parse(response.body)
      expect(response_data).to eq(expected_lead_data)
      expect(stubbed_request).to_not have_been_made
      expect(stubbed_note_request).to_not have_been_made
    end
  end

  context 'when team_size is invalid' do
    let(:options) {{
      "name" => full_options['name'],
      "email" => full_options['email'],
      "team_size" => -5,
      "phone" => full_options['phone'],
      "message" => full_options['message'],
      "referral_source" => full_options['referral_source']
    }}
    let(:expected_lead_data) {{
      "@type"         => "error",
      "error_type"    => "wrong_params",
      "error_message" => "invalid team size",
    }}

    it 'rejects the request' do
      expect(response.status).to eq(400)
      response_data = JSON.parse(response.body)
      expect(response_data).to eq(expected_lead_data)
      expect(stubbed_request).to_not have_been_made
      expect(stubbed_note_request).to_not have_been_made
    end
  end
end
