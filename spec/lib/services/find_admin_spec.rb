describe Travis::Services::FindAdmin do
  include Travis::Testing::Stubs

  describe 'find' do
    let(:result) { described_class.new(nil, repository: repository).run }

    before :each do
      allow(User).to receive(:with_permissions).with(:repository_id => repository.id, :admin => true).and_return [user]
    end

    describe 'given a user has admin access to a repository (as seen by github)' do
      it 'returns that user' do
        expect(result).to eq(user)
      end
    end

    describe 'given a user does not have access to a repository' do
      before :each do
        allow(user).to receive(:update!)
      end

      xit 'raises an exception' do
        expect { result }.to raise_error(Travis::AdminMissing, 'no admin available for svenfuchs/minimal')
      end

      xit 'revokes admin permissions for that user on our side' do
        expect(user).to receive(:update!).with(:permissions => { 'admin' => false })
        ignore_exception { result }
      end
    end

    describe 'given an error occurs while retrieving the repository info' do
      let(:error) { double('error', :backtrace => [], :response => double('response')) }

      before :each do
        allow(GH).to receive(:[]).with("repos/#{repository.slug}").and_raise(GH::Error.new(error))
      end

      xit 'raises an exception' do
        expect { result }.to raise_error(Travis::AdminMissing, 'no admin available for svenfuchs/minimal')
      end

      it 'does not revoke permissions' do
        expect(user).not_to receive(:update_permissions!)
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
    allow(User).to receive(:with_permissions).with(repository_id: repository.id, admin: true).and_return [user]
    service.run
  end

  it 'publishes a event' do
    expect(event).to publish_instrumentation_event(
      event: 'travis.services.find_admin.run:completed',
      message: 'Travis::Services::FindAdmin#run:completed for svenfuchs/minimal: svenfuchs',
      result: user
    )
  end
end
