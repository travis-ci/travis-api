describe User do
  let(:org) { FactoryBot.create(:org, :login => 'travis-organization') }

  describe 'educational_org' do
    after do
      Travis::Features.deactivate_owner(:educational_org, org)
    end

    it 'returns true if organization is flagged as educational_org' do
      Travis::Features.activate_owner(:educational_org, org)
      org.education?.should be true
    end

    it 'returns false if the organization has not been flagged as educational_org' do
      org.education?.should be false
    end
  end
end
