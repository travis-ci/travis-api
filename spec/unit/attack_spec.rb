describe Rack::Attack do
  describe 'image request' do
    let(:request) {
      env = Rack::MockRequest.env_for("https://api-test.travis-ci.org/travis-ci/travis-github-sync.png")
      Rack::Attack::Request.new(env)
    }

    it 'should be safelisted' do
      expect(Rack::Attack.configuration.safelisted?(request)).to be_truthy
    end
  end

  describe 'request from GitHub ip' do
    let(:request) {
      env = Rack::MockRequest.env_for("https://api-test.travis-ci.org/repos/rails/rails/branches", {
        'REMOTE_ADDR' => '192.30.252.42',
      })
      Rack::Attack::Request.new(env)
    }

    it 'should be safelisted' do
      expect(Rack::Attack.configuration.safelisted?(request)).to be_truthy
    end
  end

  describe 'non-safelisted request' do
    let(:request) {
      env = Rack::MockRequest.env_for("https://api-test.travis-ci.org/repos/rails/rails/branches")
      Rack::Attack::Request.new(env)
    }

    it 'should not be safelisted' do
      expect(Rack::Attack.configuration.safelisted?(request)).to be_falsey
    end
  end
end
