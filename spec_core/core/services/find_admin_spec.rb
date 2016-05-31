require 'spec_helper'

describe Travis::Services::FindAdmin do
  include Travis::Testing::Stubs

  describe 'find' do
    let(:result) { described_class.new(nil, repository: repository).run }

    before :each do
      User.stubs(:with_permissions).with(:repository_id => repository.id, :admin => true).returns [user]
    end

    describe 'given a user has admin access to a repository (as seen by github)' do
      before :each do
        GH.stubs(:[]).with("repos/#{repository.slug}").returns('permissions' => { 'admin' => true })
      end

      it 'returns that user' do
        result.should == user
      end
    end

    describe 'given a user does not have access to a repository' do
      before :each do
        GH.stubs(:[]).with("repos/#{repository.slug}").returns('permissions' => { 'admin' => false })
        user.stubs(:update_attributes!)
      end

      xit 'raises an exception' do
        lambda { result }.should raise_error(Travis::AdminMissing, 'no admin available for svenfuchs/minimal')
      end

      xit 'revokes admin permissions for that user on our side' do
        user.expects(:update_attributes!).with(:permissions => { 'admin' => false })
        ignore_exception { result }
      end
    end

    describe 'given an error occurs while retrieving the repository info' do
      let(:error) { stub('error', :backtrace => [], :response => stub('reponse')) }

      before :each do
        GH.stubs(:[]).with("repos/#{repository.slug}").raises(GH::Error.new(error))
      end

      xit 'raises an exception' do
        lambda { result }.should raise_error(Travis::AdminMissing, 'no admin available for svenfuchs/minimal')
      end

      it 'does not revoke permissions' do
        user.expects(:update_permissions!).never
        ignore_exception { result }
      end
    end

    describe 'missing repository' do
      it 'raises Travis::RepositoryMissing' do
        expect { described_class.new.run }.to raise_error(Travis::RepositoryMissing)
      end
    end

    def ignore_exception(&block)
      block.call
    rescue Travis::AdminMissing
    end
  end
end

describe Travis::Services::FindAdmin::Instrument do
  include Travis::Testing::Stubs

  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events[1] }
  let(:service)   { Travis::Services::FindAdmin.new(nil, repository: repository) }

  before :each do
    Travis::Notification.publishers.replace([publisher])
    User.stubs(:with_permissions).with(repository_id: repository.id, admin: true).returns [user]
    GH.stubs(:[]).with("repos/#{repository.slug}").returns('permissions' => { 'admin' => true })
    service.run
  end

  it 'publishes a event' do
    event.should publish_instrumentation_event(
      event: 'travis.services.find_admin.run:completed',
      message: 'Travis::Services::FindAdmin#run:completed for svenfuchs/minimal: svenfuchs',
      result: user,
    )
  end
end
