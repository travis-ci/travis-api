describe Travis::API::V3::Queries::User do
  it 'fetches the newest user if multiple users exist with the same login' do
    FactoryGirl.create(:user, login: 'travisbot')
    newer = FactoryGirl.create(:user, login: 'travisbot')

    described_class.new({ 'user.login' => 'travisbot' }, 'User').find.id.should == newer.id
  end
end
