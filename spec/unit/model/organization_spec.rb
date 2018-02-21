describe Organization do
  describe "subscribed?" do
    let(:organization) { Organization.create }
    let!(:subscription) {Subscription.create(:valid_to => Time.now + 1.day, :cc_token => "cc_1234", owner_id: organization.id, owner_type: 'Organization', source: 'manual', status: 'subscribed' )}

    it "should be subscribed when the organization has a valid subscription" do
      organization.subscribed?.should == true
    end

    it "should not be subscribed when the organization doesn't have a valid subscription" do
      subscription.valid_to = Time.now - 10.days
      subscription.save
      organization.subscribed?.should == false
    end

    it "should not be subscribed when the organization's subscription is empty" do
      Subscription.where(owner_id: organization.id, owner_type: "Organization").destroy_all
      organization.reload.subscribed?.should == false
    end
  end
end
