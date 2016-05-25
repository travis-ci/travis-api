require 'spec_helper'

describe Request::States do
  include Support::ActiveRecord

  let(:owner)      { User.new(:login => 'joshk') }
  let(:repository) { Repository.new(:name => 'travis-ci', :owner => owner, :owner_name => 'travis-ci') }
  let(:commit)     { Commit.new(:repository => repository, :commit => '12345', :branch => 'master', :message => 'message', :committed_at => Time.now, :compare_url => 'https://github.com/svenfuchs/minimal/compare/master...develop') }
  let(:request)    { Request.new(:repository => repository, :commit => commit) }

  let(:approval)   { Request::Approval.any_instance }
  let(:config)     { { :from => '.travis.yml' } }

  before :each do
    repository.save!
    Travis.stubs(:run_service).with(:github_fetch_config, is_a(Hash)).returns(config)
    request.stubs(:add_build)
    request.stubs(:creates_jobs?).returns(true)
  end

  it 'has the state :created when just created' do
    request.state.should == :created
  end

  describe 'start' do
    describe 'with an accepted request' do
      before :each do
        approval.stubs(:accepted?).returns(true)
      end

      it 'configures the request' do
        request.expects(:configure)
        request.start
      end

      it 'finishes the request' do
        request.expects(:finish)
        request.start
      end

      it 'sets the state to started' do
        request.start
        request.was_started?.should be_true
      end

      it 'sets the result to :accepted' do
        request.start
        request.result.should == :accepted
      end

      describe 'but rejected config' do
        before :each do
          approval.stubs(:config_accepted?).returns(false)
        end

        it 'does config, but resets it to nil' do
          request.expects(:fetch_config).returns({})

          request.start

          request.config.should be_nil
        end
      end

      describe 'but rejected branch' do
        before :each do
          approval.stubs(:branch_accepted?).returns(false)
        end

        it 'does config, but resets it to nil' do
          request.expects(:fetch_config).returns({})

          request.start

          request.config.should be_nil
        end
      end
    end

    describe 'with a rejected request' do
      before :each do
        approval.stubs(:accepted?).returns(false)
      end

      it 'does not configure the request' do
        request.expects(:fetch_config).never
        request.start
      end

      it 'finishes the request' do
        request.expects(:finish)
        request.start
      end

      it 'sets the state to started' do
        request.start
        request.was_started?.should be_true
      end

      it 'sets the result to :rejected' do
        request.start
        request.result.should == :rejected
      end
    end
  end

  describe 'configure' do
    it 'fetches the .travis.yml config from Github' do
      Travis.expects(:run_service).returns(config)
      request.configure
    end

    it 'merges existing configuration (e.g. from an api request)' do
      request.config = { env: 'FOO=foo' }
      request.configure
      request.config.should == config.merge(env: 'FOO=foo')
    end

    it 'stores the config on the request' do
      request.configure
      request.config.should == config
    end

    it 'sets the state to configured' do
      request.configure
      request.was_configured?.should be_true
    end
  end

  describe 'finish' do
    before :each do
      request.stubs(:config).returns('.configured' => true)
    end

    describe 'with an approved request' do
      before :each do
        approval.stubs(:approved?).returns(true)
      end

      it 'builds the build' do
        request.expects(:add_build)
        request.finish
      end

      it 'sets the state to finished' do
        request.finish
        request.should be_finished
      end
    end

    describe 'with an unapproved request' do
      before :each do
        approval.stubs(:approved?).returns(false)
      end

      it 'does not build the build' do
        request.expects(:add_build).never
        request.finish
      end

      it 'sets the state to finished' do
        request.finish
        request.should be_finished
      end
    end

    describe 'with a config parse error' do
      let(:job) { stub(start!: nil, finish!: nil, :log_content= => nil) }
      let(:build) { stub(matrix: [job], finish!: nil) }

      before :each do
        request.stubs(:add_build).returns(build)
        request.stubs(:config).returns('.result' => 'parse_error')
      end

      it 'builds the build' do
        request.expects(:add_build).returns(build)
        request.finish
      end

      it 'prints an error to the log' do
        job.expects(:log_content=)
        request.finish
      end
    end

    describe 'with a config server error' do
      let(:job) { stub(start!: nil, finish!: nil, :log_content= => nil) }
      let(:build) { stub(matrix: [job], finish!: nil) }

      before :each do
        request.stubs(:add_build).returns(build)
        request.stubs(:config).returns('.result' => 'server_error')
      end

      it 'builds the build' do
        request.expects(:add_build).returns(build)
        request.finish
      end

      it 'prints an error to the log' do
        job.expects(:log_content=)
        request.finish
      end
    end
  end

  describe 'start!' do
    before :each do
      request.stubs(:config).returns('.configured' => true)
      approval.stubs(:approved?).returns(true)
    end

    it 'finally sets the state to finished' do
      request.repository.save!
      request.repository_id = request.repository.id
      request.save!
      request.start!
      request.reload.should be_finished
    end
  end

  describe "adding a build" do
    before do
      request.unstub(:add_build)
      Travis.config.notify_on_build_created = true
    end

    after do
      request.stubs(:add_build)
      Travis.config.notify_on_build_created = false
    end

    it "should create a build" do
      request.save
      request.add_build_and_notify.should be_a(Build)
    end

    it "should notify the build" do
      request.save
      Travis::Event.expects(:dispatch).with do |event, *args|
        event.should == "build:created"
      end
      request.add_build_and_notify
    end

    it "shouldn't notify the build when the flag is disabled" do
      Travis.config.notify_on_build_created = false
      request.save
      Travis::Event.expects(:dispatch).with { |e, *| e.should == "build:created" }.never
      request.add_build_and_notify
    end
  end
end
