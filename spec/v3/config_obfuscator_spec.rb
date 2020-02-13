require 'travis/api/v3/config_obfuscator'

describe Travis::API::V3::ConfigObfuscator do
  let(:repo) { FactoryBot.create(:repository) }
  before { repo.regenerate_key! }

  it 'handles nil env' do
    config = { rvm: '1.8.7', env: nil }
    result = obfuscator = described_class.new(config, repo.key).obfuscate

    expect(result).to eq({
      rvm: '1.8.7',
      env: nil
    })
  end

  it 'leaves regular vars untouched' do
    config = { rvm: '1.8.7', env: 'FOO=foo' }
    result = obfuscator = described_class.new(config, repo.key).obfuscate

    expect(result).to eq({
      rvm: '1.8.7',
      env: 'FOO=foo'
    })
  end

  it 'obfuscates env vars given as strings, including accidents' do
    secure = Travis::SecureConfig.new(repo.key)
    config = { rvm: '1.8.7',
               env: [secure.encrypt('BAR=barbaz'), secure.encrypt('PROBLEM'), 'FOO=foo']
             }
    result = obfuscator = described_class.new(config, repo.key).obfuscate

    expect(result).to eq({
      rvm: '1.8.7',
      env: 'BAR=[secure] [secure] FOO=foo'
    })
  end

  it 'obfuscates env vars given as hashes' do
    secure = Travis::SecureConfig.new(repo.key)
    config = { rvm: '1.8.7',
               env: { BAR: secure.encrypt('bar'), FOO: 'foo' }
             }
    result = obfuscator = described_class.new(config, repo.key).obfuscate

    expect(result).to eq({
      rvm: '1.8.7',
      env: 'BAR=[secure] FOO=foo'
    })
  end

  it 'handles nil secure var' do
    secure = Travis::SecureConfig.new(repo.key)
    config = { rvm: '1.8.7',
               env: [{ secure: nil }, { secure: secure.encrypt('FOO=foo') }],
               global_env: [{ secure: nil }, { secure: secure.encrypt('BAR=bar') }]
             }
    result = obfuscator = described_class.new(config, repo.key).obfuscate

    expect(result).to eq({
      rvm: '1.8.7',
      env: 'FOO=[secure]',
      global_env: 'BAR=[secure]'
    })
  end

  it 'normalizes env vars which are hashes to strings' do
    secure = Travis::SecureConfig.new(repo.key)
    config = { rvm: '1.8.7',
               env: [{FOO: 'bar', BAR: 'baz'},
                      secure.encrypt('BAR=barbaz')]
             }
    result = obfuscator = described_class.new(config, repo.key).obfuscate

    expect(result).to eq({
      rvm: '1.8.7',
      env: 'FOO=bar BAR=baz BAR=[secure]'
    })
  end

  it 'removes addons config if it is not a hash' do
    config = { rvm: '1.8.7',
               addons: "foo",
             }
    result = obfuscator = described_class.new(config, repo.key).obfuscate

    expect(result).to eq({
      rvm: '1.8.7'
    })
  end

  it 'removes addons items which are not safelisted' do
    config = { rvm: '1.8.7',
               addons: { sauce_connect: true, firefox: '22.0' },
             }
    result = obfuscator = described_class.new(config, repo.key).obfuscate

    expect(result).to eq({
      rvm: '1.8.7',
      addons: {
        firefox: '22.0'
      }
    })
  end

  it 'removes source key' do
    config = { rvm: '1.8.7',
               source_key: '1234'
             }
    result = obfuscator = described_class.new(config, repo.key).obfuscate

    expect(result).to eq({
      rvm: '1.8.7',
    })
  end
end
