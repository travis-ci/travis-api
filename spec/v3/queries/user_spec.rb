describe Travis::API::V3::Queries::User do
  it 'fetches the newest user if multiple users exist with the same login' do
    FactoryBot.create(:user, login: 'travisbot')
    newer = FactoryBot.create(:user, login: 'travisbot')

    described_class.new({ 'user.login' => 'travisbot' }, 'User').find.id.should == newer.id
  end
end
