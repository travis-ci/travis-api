describe Travis::API::V3::Models::Mailer do
  subject { Travis::API::V3::Models::Mailer.new }

  let(:user) { FactoryBot.create(:user) }
  let(:organization) { FactoryBot.create(:org_v3) }
  let!(:membership)  { FactoryBot.create(:membership, user: user, organization: organization) }

  describe '#send_beta_confirmation' do
    it 'sends email' do
      subject.expects(:send_email).with(
        'Travis::Addons::Migration::Task',
        'beta_confirmation',
        user_name: user.login,
        recipients: [user.email],
        organizations: [organization.name]
      )

      subject.send_beta_confirmation(user)
    end
  end

  describe '#send_email' do
    let(:redis_client) { double('Redis') }

    before { subject.stubs(client: redis_client) }

    it 'pushes a task to redis' do
      redis_client.expects(:push).with(
        'queue' => 'email',
        'class' => 'Travis::Async::Sidekiq::Worker',
        'args' => [nil, 'Travis::Addons::Migration::Task', 'perform', {}, { email_type: 'some_email', foo: 'bar' }]
      )

      subject.send_email('Travis::Addons::Migration::Task', 'some_email', foo: 'bar')
    end
  end
end
