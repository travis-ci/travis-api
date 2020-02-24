describe Organization do
  describe "subscribed?" do
    let(:organization) { Organization.create }
    let!(:subscription) {Subscription.create(:valid_to => Time.now + 1.day, :cc_token => "cc_1234", owner_id: organization.id, owner_type: 'Organization', source: 'manual', status: 'subscribed' )}

    it "should be subscribed when the organization has a valid subscription" do
      expect(organization.subscribed?).to eq(true)
    end

    it "should not be subscribed when the organization doesn't have a valid subscription" do
      subscription.valid_to = Time.now - 10.days
      subscription.save
      expect(organization.subscribed?).to eq(false)
    end

    it "should not be subscribed when the organization's subscription is empty" do
      Subscription.where(owner_id: organization.id, owner_type: "Organization").destroy_all
      expect(organization.reload.subscribed?).to eq(false)
    end
  end
end
