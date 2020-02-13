describe Build::Config::Obfuscate do
  let(:repo)  { FactoryBot.create(:repository) }
  let(:build) { Build.new(repository: repo) }

  before { repo.regenerate_key! }

  it 'normalizes env vars which are hashes to strings' do
    encrypted = repo.key.secure.encrypt('BAR=barbaz')
    build.config = {
      language: 'ruby',
      env: [[encrypted, 'FOO=foo'], [{ ONE: 1, TWO: '2' }]]
    }

    expect(build.obfuscated_config).to eq({
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      env: ['BAR=[secure] FOO=foo', 'ONE=1 TWO=2']
    })
  end

  it 'leaves regular vars untouched' do
    build.config = {
      rvm: ['1.8.7'], env: ['FOO=foo']
    }

    expect(build.obfuscated_config).to eq({
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7'],
      env: ['FOO=foo']
    })
  end

  it 'obfuscates env vars' do
    encrypted = build.repository.key.secure.encrypt('BAR=barbaz')
    build.config = {
      rvm: ['1.8.7'],
      env: [[encrypted, 'FOO=foo'], 'BAR=baz']
    }

    expect(build.obfuscated_config).to eq({
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7'],
      env: ['BAR=[secure] FOO=foo', 'BAR=baz']
    })
  end

  it 'obfuscates env vars which are not in nested array' do
    build.config = {
      rvm: ['1.8.7'],
      env: [build.repository.key.secure.encrypt('BAR=barbaz')]
    }

    expect(build.obfuscated_config).to eq({
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7'],
      env: ['BAR=[secure]']
    })
  end

  it 'works with nil values' do
    build.config = {
      rvm: ['1.8.7'],
      env: [[nil, { secure: '' }]]
    }
    expect(build.obfuscated_config).to eq({
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7'],
      env:  ['']
    })
  end

  it 'does not make an empty env key an array but leaves it empty' do
    build.config = {
      rvm: ['1.8.7'],
      env:  nil
    }
    expect(build.obfuscated_config).to eq({
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7'],
      env:  nil
    })
  end

  it 'removes source key' do
    build.config = {
      rvm: ['1.8.7'],
      source_key: '1234'
    }
    expect(build.obfuscated_config).to eq({
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7']
    })
  end
end
