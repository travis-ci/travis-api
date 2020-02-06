describe Travis::API::V3::Queries::Organization do
  it 'fetches the newest user if multiple users exist with the same login' do
    FactoryGirl.create(:org, login: 'travisbot')
    newer = FactoryGirl.create(:org, login: 'travisbot')

    described_class.new({ 'organization.login' => 'travisbot' }, 'Organization').find.id.should == newer.id
  end
end
