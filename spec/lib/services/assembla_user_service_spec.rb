require 'spec_helper'

RSpec.describe Travis::Services::AssemblaUserService do
  let(:payload) do
    {
      'id' => '12345',
      'email' => 'test@example.com',
      'login' => 'testuser',
      'refresh_token' => 'refresh123',
      'space_id' => '67890'
    }
  end

  let(:service) { described_class.new(payload) }
  let(:user) { double('User', id: 1, login: 'testuser', email: 'test@example.com', name: 'Test User') }
  let(:organization) { double('Organization', id: 2) }

  describe '#initialize' do
    it 'stores the payload' do
      expect(service.instance_variable_get(:@payload)).to eq(payload)
    end
  end

  describe '#find_or_create_user' do
    let(:expected_attrs) do
      {
        vcs_id: '12345',
        email: 'test@example.com',
        login: 'testuser',
        vcs_type: 'AssemblaUser'
      }
    end

    before do
      allow(::User).to receive(:find_or_create_by!).with(expected_attrs).and_return(user)
      allow(user).to receive(:update)
      allow(Travis::RemoteVCS::User).to receive(:new).and_return(double(sync: true))
    end

    it 'finds or creates a user with correct attributes' do
      expect(::User).to receive(:find_or_create_by!).with(expected_attrs)
      service.find_or_create_user
    end

    it 'returns the user' do
      result = service.find_or_create_user
      expect(result).to eq(user)
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
    let(:organizations_relation) { double('organizations') }
    let(:expected_attrs) do
      {
        vcs_id: '67890',
        vcs_type: 'AssemblaOrganization'
      }
    end

    before do
      allow(user).to receive(:organizations).and_return(organizations_relation)
    end

    it 'finds or creates organization with correct attributes' do
      expect(organizations_relation).to receive(:find_or_create_by).with(expected_attrs).and_return(organization)
      
      result = service.find_or_create_organization(user)
      expect(result).to eq(organization)
    end
  end

  describe '#create_org_subscription' do
    let(:billing_client) { double('BillingClient') }
    let(:expected_subscription_params) do
      {
        'plan' => 'beta_plan',
        'organization_id' => 2,
        'billing_info' => {
          'address' => 'System-generated for user testuser (1)',
          'city' => 'AutoCity-1',
          'country' => 'Poland',
          'first_name' => 'Test',
          'last_name' => 'User',
          'zip_code' => '0001',
          'billing_email' => 'test@example.com'
        },
        'credit_card_info' => { 'token' => nil }
      }
    end

    before do
      allow(Travis::API::V3::BillingClient).to receive(:new).with(1).and_return(billing_client)
    end

    it 'creates a billing client with user id' do
      expect(Travis::API::V3::BillingClient).to receive(:new).with(1)
      allow(billing_client).to receive(:create_v2_subscription)
      
      service.create_org_subscription(user, 2)
    end

    it 'calls create_v2_subscription with correct params' do
      expect(billing_client).to receive(:create_v2_subscription).with(expected_subscription_params)
      
      service.create_org_subscription(user, 2)
    end

    context 'when billing client raises an error' do
      let(:error) { StandardError.new('Billing error') }

      it 'returns error hash' do
        allow(billing_client).to receive(:create_v2_subscription).and_raise(error)
        
        result = service.create_org_subscription(user, 2)
        expect(result).to eq({ error: true, details: 'Billing error' })
      end
    end

    context 'when user has no name' do
      let(:user_without_name) { double('User', id: 1, login: 'testuser', email: 'test@example.com', name: nil) }

      it 'handles nil name gracefully' do
        expected_params = expected_subscription_params.dup
        expected_params['billing_info']['first_name'] = nil
        expected_params['billing_info']['last_name'] = nil

        expect(billing_client).to receive(:create_v2_subscription).with(expected_params)
        
        service.create_org_subscription(user_without_name, 2)
      end
    end
  end
end
