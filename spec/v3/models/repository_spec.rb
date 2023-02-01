# frozen_string_literal: true
describe Travis::API::V3::Models::Repository do
  let(:repo) { FactoryBot.build :repository }
  let(:v3_repo) { described_class.new(repo.attributes) }
  
  describe '#perforce?' do
    subject { v3_repo.perforce? }

    context 'when server_type is perforce' do
      before { v3_repo.server_type = 'perforce' }

      it { is_expected.to be true }
    end
    
    context 'when server_type is not' do
      before { v3_repo.server_type = 'git' }

      it { is_expected.to be false }
    end
  end
  
  describe '#subversion?' do
    subject { v3_repo.subversion? }

    context 'when server_type is subversion' do
      before { v3_repo.server_type = 'subversion' }

      it { is_expected.to be true }
    end
    
    context 'when server_type is not' do
      before { v3_repo.server_type = 'git' }

      it { is_expected.to be false }
    end
  end
end