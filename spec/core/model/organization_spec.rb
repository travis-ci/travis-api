require 'spec_helper'

describe User do
  include Support::ActiveRecord

    let(:org)    { Factory.create(:org, :login => 'travis-organization') }

    describe 'educational_org' do
      after do
        Travis::Features.deactivate_owner(:educational_org, org)
      end

      it 'returns true if organization is flagged as educational_org' do
        Travis::Features.activate_owner(:educational_org, org)
        org.education?.should be_true
      end

      it 'returns false if the organization has not been flagged as educational_org' do
        org.education?.should be_false
      end
    end
end