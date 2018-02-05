describe Travis::API::V3::Queries::Organization do
  it 'fetches the newest user if multiple users exist with the same login' do
    Factory(:org, login: 'travisbot')
    newer = Factory(:org, login: 'travisbot')

    described_class.new({ 'organization.login' => 'travisbot' }, 'Organization').find.id.should == newer.id
  end
end
