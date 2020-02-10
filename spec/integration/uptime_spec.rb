describe 'Uptime', set_app: true do
  after do
    ActiveRecord::Base.connection.unstub(:execute)
  end

  it 'returns a 200 and ok when the request was successful' do
    response = get '/uptime'
    expect(response.status).to eq(200)
    expect(response.body).to eq("OK")
  end

  it "returns a 500 when the query wasn't successful" do
    ActiveRecord::Base.connection.stubs(:execute).raises(StandardError, 'error!')
    response = get '/uptime'
    expect(response.status).to eq(500)
    expect(response.body).to eq("Error: error!")
  end
end
