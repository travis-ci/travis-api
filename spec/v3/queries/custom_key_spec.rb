describe Travis::API::V3::Queries::CustomKey do
  let(:private_key) { OpenSSL::PKey::RSA.new(TEST_PRIVATE_KEY).to_pem }

  context 'owner type is user' do
    let(:user) { FactoryBot.create(:user) }
    let(:params) do
      {
        'owner_id' => user.id,
        'owner_type' => 'User',
        'added_by' => user.id,
        'name' => 'TEST_KEY',
        'private_key' => private_key,
        'description' => ''
      }
    end

    context 'key with identifier does not exist in user or organization' do
      it 'creates custom key' do  
        expect(described_class.new({}, 'CustomKey').create(params, user).fingerprint).to eq('57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40')
      end
    end
  
    context 'key with identifier exists for this user' do
      before do
        Travis::API::V3::Models::CustomKey.new.save_key!(
          params['owner_type'],
          params['owner_id'],
          params['name'],
          params['description'],
          params['private_key'],
          params['added_by']
        )
      end

      it 'returns error' do  
        expect { described_class.new({}, 'CustomKey').create(params, user) }.to raise_error(Travis::API::V3::UnprocessableEntity)
      end
    end

    context 'key with identifier exists for users organization' do
      let(:org) { FactoryBot.create(:org) }
      let!(:membership) { org.memberships.create(user: user, role: 'admin', build_permission: true) }

      before do
        Travis::API::V3::Models::CustomKey.new.save_key!(
          'Organization',
          org.id,
          params['name'],
          params['description'],
          params['private_key'],
          params['added_by']
        )
      end

      it 'returns error' do  
        expect { described_class.new({}, 'CustomKey').create(params, user) }.to raise_error(Travis::API::V3::UnprocessableEntity)
      end
    end
  end

  context 'owner type is organization' do
    let(:org) { FactoryBot.create(:org) }
    let(:user) { FactoryBot.create(:user) }
    let!(:membership) { org.memberships.create(user: user, role: 'admin', build_permission: true) }
    let(:params) do
      {
        'owner_id' => org.id,
        'owner_type' => 'Organization',
        'added_by' => user.id,
        'name' => 'TEST_KEY',
        'private_key' => private_key,
        'description' => ''
      }
    end

    context 'key with identifier does not exist in user or organization' do
      it 'creates custom key' do  
        expect(described_class.new({}, 'CustomKey').create(params, user).fingerprint).to eq('57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40')
      end
    end

    context 'key with identifier exists for this user' do
      before do
        Travis::API::V3::Models::CustomKey.new.save_key!(
          'User',
          user.id,
          params['name'],
          params['description'],
          params['private_key'],
          params['added_by']
        )
      end

      it 'returns error' do  
        expect { described_class.new({}, 'CustomKey').create(params, user) }.to raise_error(Travis::API::V3::UnprocessableEntity)
      end
    end
  end
end
