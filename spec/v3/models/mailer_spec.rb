describe Travis::API::V3::Models::Mailer do
  subject { Travis::API::V3::Models::Mailer.new }

  let(:user) { FactoryBot.create(:user) }
  let(:organization) { FactoryBot.create(:org_v3) }
  let!(:membership)  { FactoryBot.create(:membership, user: user, organization: organization) }

  describe '#send_beta_confirmation' do
    it 'sends email' do
      expect(subject).to receive(:send_email).with(
        'Travis::Addons::Migration::Task',
        'beta_confirmation',
        { user_name: user.login,
          recipients: [user.email],
          organizations: [organization.name] }
      )

      subject.send_beta_confirmation(user)
    end
  end

  describe '#send_email' do
    let(:redis_client) { double('Redis') }

    before { allow(subject).to receive(:client).and_return(redis_client) }

    it 'pushes a task to redis' do
      expect(redis_client).to receive(:push).with(
        'queue' => 'email',
        'class' => 'Travis::Async::Sidekiq::Worker',
        'args' => [nil, 'Travis::Addons::Migration::Task', 'perform', {}, { foo: 'bar', email_type: 'some_email' }].map! {|arg| arg.to_json}
      )

      subject.send_email('Travis::Addons::Migration::Task', 'some_email', foo: 'bar')
    end
  end
end
