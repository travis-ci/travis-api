describe Travis::API::V3::Queries::UserBuilds do
  let(:user)  { Travis::API::V3::Models::User.find_by_login('svenfuchs') }

  let(:subject){ described_class.new({ 'user.id' => user.id }, 'User' ) }

  let(:build_count) { 3 }

  describe "#find" do


    context "with a valid user id who has builds" do
      before do
        FactoryGirl.create_list(:build, build_count, { sender_id: user.id, sender_type: 'User' })
      end

      it 'fetches a list of builds for a given user_id' do
        results = subject.find

        expect(results.respond_to?(:each)).to be_truthy
        expect(results.count).to eq build_count
      end
    end

    context "with a valid user who does not have builds" do
      it "returns an empty enumerable" do
        results = subject.find

        expect(results.respond_to?(:each)).to be_truthy
        expect(results.count).to eq 0
      end
    end

    context "when user.id is missing from params" do
      let(:subject){ described_class.new({ }, 'User' ) }

      it "returns an empty enumerable" do
        results = subject.find

        expect(results.respond_to?(:each)).to be_truthy
        expect(results.count).to eq 0
      end
    end
  end
end
