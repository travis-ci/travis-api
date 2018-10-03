describe Travis::API::V3::Renderer::Repository do
   let(:repo) { Factory(:repository) }

  subject { Travis::API::V3::Renderer::Repository.new(repo) }

  describe "basic check" do
    it "returns a basic representation of the object" do
      expect(subject).to be_a Travis::API::V3::Renderer::Repository
    end
  end

  describe "#display_migration_ui" do
    it "is included in the :additional representation set" do
      expect(subject.class.representations[:additional]).to include(:display_migration_ui)
    end

    it "returns false when owner is not active" do
      expect(subject.display_migration_ui).to be_falsey
    end

    it "returns true when owner is active" do
      Travis::Features.expects(:owner_active?).with(:display_migration_ui, repo.owner).returns(true)

      expect(subject.display_migration_ui).to be_truthy
    end
  end
end
