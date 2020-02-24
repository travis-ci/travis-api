describe Travis::API::V3::Renderer::Repository do
  let(:repo) { FactoryBot.create(:repository_without_last_build) }
  let(:repo_renderer) { Travis::API::V3::Renderer::Repository.new(repo) }

  subject { repo_renderer }

  describe "basic check" do
    it "returns a basic representation of the object" do
      expect(subject).to be_a Travis::API::V3::Renderer::Repository
    end
  end

  describe '#allow_migration' do
    subject { repo_renderer.allow_migration }

    it 'is included in the :additional representation set' do
      expect(repo_renderer.class.representations[:additional]).to include(:allow_migration)
    end

    context 'when feature is not enabled for the user' do
      it { is_expected.to be_falsey }
    end

    context 'when feature is enabled for the user' do
      before { expect(Travis::Features).to receive(:owner_active?).with(:allow_migration, repo.owner).and_return(true) }

      it { is_expected.to be_truthy }
    end
  end
end
