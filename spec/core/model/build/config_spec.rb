require 'spec_helper'

describe Build::Config do
  include Support::ActiveRecord

  it 'keeps the given env if it is an array' do
    config = YAML.load %(
      env:
        - FOO=foo
        - BAR=bar
    )
    Build::Config.new(config).normalize.slice(:env, :global_env).should == {
      env: [
        'FOO=foo',
        'BAR=bar'
      ]
    }
  end

  # seems odd. is this on purpose?
  it 'normalizes an env vars hash to an array of strings' do
    config = YAML.load %(
      env:
        FOO: foo
        BAR: bar
    )
    Build::Config.new(config).normalize.slice(:env, :global_env).should == {
      env: [
        'FOO=foo BAR=bar'
      ]
    }
  end

  it 'keeps env vars global and matrix arrays' do
    config = YAML.load %(
      env:
        global:
          - FOO=foo
          - BAR=bar
        matrix:
          - BAZ=baz
          - BUZ=buz
    )
    Build::Config.new(config).normalize.slice(:env, :global_env).should == {
      global_env: [
        'FOO=foo',
        'BAR=bar'
      ],
      env: [
        'BAZ=baz',
        'BUZ=buz'
      ]
    }
  end

  # seems odd. is this on purpose?
  it 'normalizes env vars global and matrix which are hashes to an array of strings' do
    config = YAML.load %(
      env:
        global:
          FOO: foo
          BAR: bar
        matrix:
          BAZ: baz
          BUZ: buz
    )
    Build::Config.new(config).normalize.slice(:env, :global_env).should == {
      global_env: [
        'FOO=foo BAR=bar'
      ],
      env: [
        'BAZ=baz BUZ=buz'
      ]
    }
  end

  it 'works fine if matrix part of env is undefined' do
    config = YAML.load %(
      env:
        global: FOO=foo
    )
    Build::Config.new(config).normalize.slice(:env, :global_env).should == {
      global_env: [
        'FOO=foo'
      ]
    }
  end

  it 'works fine if global part of env is undefined' do
    config = YAML.load %(
      env:
        matrix: FOO=foo
    )
    Build::Config.new(config).normalize.slice(:env, :global_env).should == {
      env: [
        'FOO=foo'
      ]
    }
  end

  # Seems odd. What's the usecase? Broken yaml?
  it 'keeps matrix and global config as arrays, not hashes' do
    config = YAML.load %(
      env:
        global: FOO=foo
        matrix:
          -
            - BAR=bar
            - BAZ=baz
          - BUZ=buz
    )
    Build::Config.new(config).normalize.slice(:env, :global_env).should == {
      global_env: [
        'FOO=foo'
      ],
      env: [
        ['BAR=bar', 'BAZ=baz'],
        'BUZ=buz'
      ]
    }
  end

  # Seems super odd. Do people actually pass such stuff?
  it 'keeps wild nested array/hashes structure' do
    config = YAML.load %(
      env:
        -
          -
            secure: encrypted-value
          - FOO=foo
        -
          -
            BAR: bar
            BAZ: baz
    )
    Build::Config.new(config).normalize.slice(:env, :global_env).should == {
      env: [
        [{ secure: 'encrypted-value' }, 'FOO=foo'],
        ['BAR=bar BAZ=baz']
      ]
    }
  end

  it 'sets the os value to osx for objective-c builds' do
    config = YAML.load %(
      language: objective-c
    )
    Build::Config.new(config).normalize[:os].should == 'osx'
  end

  it 'sets the os value to linux for other builds' do
    config = YAML.load %(
    )
    Build::Config.new(config).normalize[:os].should == 'linux'
  end
end
