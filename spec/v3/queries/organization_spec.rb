describe Travis::API::V3::Queries::Organization do
  it 'fetches the newest user if multiple users exist with the same login' do
    FactoryBot.create(:org, login: 'travisbot')
    newer = FactoryBot.create(:org, login: 'travisbot')

    expect(described_class.new({ 'organization.login' => 'travisbot' }, 'Organization').find.id).to eq(newer.id)
  end
end
