require 'spec_helper'

describe Build::Config::Obfuscate do
  include Support::ActiveRecord

  let(:repo)  { Factory(:repository) }
  let(:build) { Build.new(repository: repo) }

  it 'normalizes env vars which are hashes to strings' do
    encrypted = repo.key.secure.encrypt('BAR=barbaz')
    build.config = {
      language: 'ruby',
      env: [[encrypted, 'FOO=foo'], [{ ONE: 1, TWO: '2' }]]
    }

    build.obfuscated_config.should == {
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      env: ['BAR=[secure] FOO=foo', 'ONE=1 TWO=2']
    }
  end

  it 'leaves regular vars untouched' do
    build.config = {
      rvm: ['1.8.7'], env: ['FOO=foo']
    }

    build.obfuscated_config.should == {
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7'],
      env: ['FOO=foo']
    }
  end

  it 'obfuscates env vars' do
    encrypted = build.repository.key.secure.encrypt('BAR=barbaz')
    build.config = {
      rvm: ['1.8.7'],
      env: [[encrypted, 'FOO=foo'], 'BAR=baz']
    }

    build.obfuscated_config.should == {
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7'],
      env: ['BAR=[secure] FOO=foo', 'BAR=baz']
    }
  end

  it 'obfuscates env vars which are not in nested array' do
    build.config = {
      rvm: ['1.8.7'],
      env: [build.repository.key.secure.encrypt('BAR=barbaz')]
    }

    build.obfuscated_config.should == {
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7'],
      env: ['BAR=[secure]']
    }
  end

  it 'works with nil values' do
    build.config = {
      rvm: ['1.8.7'],
      env: [[nil, { secure: '' }]]
    }
    build.obfuscated_config.should == {
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7'],
      env:  ['']
    }
  end

  it 'does not make an empty env key an array but leaves it empty' do
    build.config = {
      rvm: ['1.8.7'],
      env:  nil
    }
    build.obfuscated_config.should == {
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7'],
      env:  nil
    }
  end

  it 'removes source key' do
    build.config = {
      rvm: ['1.8.7'],
      source_key: '1234'
    }
    build.obfuscated_config.should == {
      language: 'ruby',
      os: 'linux',
      group: 'stable',
      dist: 'precise',
      rvm: ['1.8.7']
    }
  end
end
