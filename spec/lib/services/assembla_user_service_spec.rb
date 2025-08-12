require 'spec_helper'

RSpec.describe Travis::Services::AssemblaUserService do
  let(:payload) do
    {
      'id' => '12345',
      'name' => 'Test User',
      'email' => 'test@example.com',
      'login' => 'testuser',
      'refresh_token' => 'refresh123',
      'space_id' => '67890'
    }
  end

  let(:service) { described_class.new(payload) }
  let(:user) { FactoryBot.create(:user, vcs_id: payload['id'], email: payload['email'], login: payload['login'], name: payload['name']) }
  let(:organization) { FactoryBot.create(:org, vcs_id: payload['space_id'], vcs_type: 'AssemblaOrganization') }

  describe '#find_or_create_user' do
    let(:expected_attrs) do
      {
        vcs_id: payload['id'],
        email: payload['email'],
        name: payload['name'],
        login: payload['login'],
        vcs_type: 'AssemblaUser'
      }
    end

    before do
      allow(Travis::RemoteVCS::User).to receive(:new).and_return(double(sync: true))
    end

    it 'finds or creates a user with correct attributes' do
      service_user = service.find_or_create_user
      expect(service_user.login).to eq(expected_attrs[:login])
      expect(service_user.email).to eq(expected_attrs[:email])
      expect(service_user.name).to eq(expected_attrs[:name])
      expect(service_user.vcs_id).to eq(expected_attrs[:vcs_id])
      expect(service_user.confirmed_at).to be_present
    end

    context 'when sync fails' do
      it 'raises SyncError' do
        allow(Travis::RemoteVCS::User).to receive(:new).and_raise(StandardError.new('Sync failed'))
        
        expect { service.find_or_create_user }.to raise_error(
          Travis::Services::AssemblaUserService::SyncError,
          'Failed to sync user: Sync failed'
        )
      end
    end
  end

  describe '#find_or_create_organization' do
    let(:expected_attrs) do
      {
        vcs_id: payload['space_id'],
        vcs_type: 'AssemblaOrganization'
      }
    end

    it 'finds or creates organization with correct attributes' do
      service_org = service.find_or_create_organization(user)
      
      expect(service_org.vcs_type).to eq(expected_attrs[:vcs_type])
      expect(service_org.vcs_id).to eq(expected_attrs[:vcs_id])
    end

    it 'has admin membership' do
      service_org = service.find_or_create_organization(user)
      expect(service_org.memberships.find_by(user: user).role).to eq('admin')
    end
  end

  describe '#create_org_subscription' do
    let(:billing_client) { double('BillingClient') }

    before do
      allow(Travis::API::V3::BillingClient).to receive(:new).with(user.id).and_return(billing_client)
    end

    context 'when billing client raises an error' do
      let(:error) { StandardError.new('Billing error') }

      it 'returns error hash' do
        allow(billing_client).to receive(:create_v2_subscription).and_raise(error)
        
        result = service.create_org_subscription(user, organization.id)
        expect(result[:error]).to be_truthy
        expect(result[:details]).to eq(error.message)
      end
    end
  end
end
