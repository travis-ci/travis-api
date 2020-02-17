describe Travis::API::V3::ServiceIndex, set_app: true do
  let(:headers) {{  }}
  let(:path)      { "/v3/repo/1/activate"         }
  let(:json)      { JSON.load(response.body) }
  let(:response)  { get(path, {}, headers)   }
  let(:resources) { json.fetch('resources')  }

  it "handles wrong HTTP method with 405 status" do
    expect(response.status).to eq(405)
  end
end
