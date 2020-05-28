describe Travis::Api::App::Middleware::UserAgentTracker do
  before do
    mock_app do
      use Travis::Api::App::Middleware::UserAgentTracker
      get('/') { 'ok' }
      get('/uptime') { 'OK' }
    end
  end

  def expect_meter(name)
    allow(Metriks).to receive(:meter).with(name).and_return(double("meter", mark: nil))
  end

  def get(env = {}, path = '/')
    env['HTTP_USER_AGENT'] ||= agent if agent
    super(path, {}, env)
  end

  context 'missing User-Agent' do
    let(:agent) { }

    it "tracks it" do
      expect_meter("api.v2.user_agent.missing")
      expect(get).to be_ok
    end

    it "denies request if require_user_agent feature is enabled" do
      allow(Travis::Features).to receive(:feature_active?).with(:require_user_agent).and_return(true)
      expect(get.status).to eq(400)
    end

    specify do
      expect(Metriks).to_not receive(:meter)
      get({}, '/uptime')
    end
  end

  context 'web browser' do
    let(:agent) { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.36 Safari/537.36" }

    specify 'without X-User-Agent' do
      expect_meter("api.v2.user_agent.browser.chrome")
      get
    end

    specify 'with X-User-Agent' do
      expect_meter("api.v2.user_agent.browser.travis-web")
      get('HTTP_X_USER_AGENT' => 'travis-web')
    end
  end

  context 'console' do
    let(:agent) { 'curl' }
    specify do
      expect_meter("api.v2.user_agent.console.curl")
      get
    end
  end

  context 'travis-api-wrapper' do
    let(:agent) { 'travis-api-wrapper - v0.01 - (cmaujean@gmail.com)' }
    specify do
      expect_meter("api.v2.user_agent.script.node_js.travis-api-wrapper")
      get
    end
  end

  context 'TravisPy' do
    let(:agent) { 'TravisPy' }
    specify do
      expect_meter("api.v2.user_agent.script.python.travispy")
      get
    end
  end

  context 'Ruby' do
    let(:agent) { 'Ruby' }
    specify do
      expect_meter("api.v2.user_agent.script.ruby.vanilla")
      get
    end
  end

  context 'Faraday' do
    let(:agent) { 'Faraday' }
    specify do
      expect_meter("api.v2.user_agent.script.ruby.vanilla")
      get
    end
  end

  context 'travis.rb' do
    let(:agent) { 'Travis/1.6.8 (Mac OS X 10.9.2 like Darwin; Ruby 2.1.1p42; RubyGems 2.0.14) Faraday/0.8.9 Typhoeus/0.6.7' }
    specify do
      expect_meter("api.v2.user_agent.script.ruby.travis.version.1.6.8")
      get
    end

    context 'Travis-API-Version header' do
      specify "with Travis-API-Version: 3" do
        expect_meter("api.v3.user_agent.script.ruby.travis.version.1.6.8")
        get('HTTP_TRAVIS_API_VERSION' => '3')
      end

      specify "with Travis-API-Version: 1.7f" do
        expect_meter("api.v1.7.user_agent.script.ruby.travis.version.1.6.8")
        get('HTTP_TRAVIS_API_VERSION' => '1.7')
      end
    end
  end

  context 'Travis CLI' do
    let(:agent) { 'Travis/1.6.8 (Mac OS X 10.10.2 like Darwin; Ruby 2.1.1; RubyGems 2.0.14; command whoami) Faraday/0.8.9 Typhoeus/0.6.7' }
    specify do
      expect_meter("api.v2.user_agent.cli.version.1.6.8")
      expect_meter("api.v2.user_agent.cli.command.whoami")
      get
    end
  end

  context 'get /uptime' do
    let(:agent) { 'Travis/1.6.8 (Mac OS X 10.9.2 like Darwin; Ruby 2.1.1p42; RubyGems 2.0.14) Faraday/0.8.9 Typhoeus/0.6.7' }
    specify do
      expect(Metriks).to_not receive(:meter)
      get({}, '/uptime')
    end
  end
end
