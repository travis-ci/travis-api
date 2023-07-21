describe Travis::Services::SyncUser do
  include Travis::Testing::Stubs

  let(:publisher) { double('publisher', :publish => true) }
  let(:service)   { described_class.new(user, {}) }

  describe 'given the user is not currently syncing' do
    before :each do
      allow(user).to receive(:update_column)
      allow(user).to receive(:syncing?).and_return(false)
    end

    it 'enqueues a sync job' do
      expect(Sidekiq::Client).to receive(:push).with(
        'queue' => 'sync',
        'class' => 'Travis::GithubSync::Worker',
        'args'  => [:sync_user, { user_id: user.id }].map! {|arg| arg.to_json}
      )
      service.run
    end

    it 'sets the user to syncing' do
      expect(user).to receive(:update_column).with(:is_syncing, true)
      service.run
    end
  end

  describe 'given the user is currently syncing' do
    before :each do
      allow(user).to receive(:syncing?).and_return(true)
    end

    it 'does not set the user to syncing' do
      expect(user).not_to receive(:update_column)
      service.run
    end
  end
end
