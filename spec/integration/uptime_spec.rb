describe 'Uptime', set_app: true do
  it 'returns a 200 and ok when the request was successful' do
    response = get '/uptime'
    expect(response.status).to eq(200)
    expect(response.body).to eq("OK")
  end

  it "returns a 500 when the query wasn't successful" do
    allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, 'error!')
    response = get '/uptime'
    expect(response.status).to eq(500)
    expect(response.body).to eq("Error: error!")
    allow(ActiveRecord::Base.connection).to receive(:execute).and_call_original
  end
end
