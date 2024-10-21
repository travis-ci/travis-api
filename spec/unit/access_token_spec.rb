describe Travis::Api::App::AccessToken do
  it 'errors out on wrong type of :expires_in argument' do
    expect {
      described_class.new(app_id: 1, user_id: 2, expires_in: 'foo')
    }.to raise_error(ArgumentError, 'expires_in must be of integer type')
  end

  it 'allows to skip expires_in' do
    expect {
      described_class.new(app_id: 1, user_id: 2, expires_in: nil)
    }.to_not raise_error
  end

  it 'does not reuse token if expires_in is set' do
    token     = described_class.new(app_id: 1, user_id: 2).tap(&:save)
    new_token = described_class.new(app_id: 1, user_id: 2, expires_in: 10)

    expect(token.token).not_to eq(new_token.token)
  end

  it 'expires the token after given period of time' do
    token = described_class.new(app_id: 1, user_id: 2).tap(&:save)
    key = "t:#{token.token}"
    Travis.redis.expire(key, 1)

    expect(Travis.redis.exists(key)).to eq 1

    sleep 2

    expect(Travis.redis.exists(key)).to eq 0
  end

  it 'allows to save extra information' do
    attrs = {
      app_id: 1,
      user_id: 3,
      expires_in: 1,
      extra: {
        required_params: { job_id: '1' }
      }
    }

    token = described_class.new(attrs).tap(&:save)
    expect(token.extra).to eq(attrs[:extra])

    token = described_class.find_by_token(token.token)
    expect(token.extra).to eq({ 'required_params' => { 'job_id' => '1' } })
  end

  it 'allows to save travis token' do
    attrs = {
      app_id: 1,
      user_id: 3,
      travis_token: Token.new
    }

    token = described_class.new(attrs).tap(&:save)
    expect(token.travis_token).to eq(attrs[:travis_token])
  end
end
