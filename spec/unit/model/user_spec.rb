describe User do
  describe "subscribed?" do
    let(:user) { User.create }
    let!(:subscription) { Subscription.create(:valid_to => Time.now + 1.day, :cc_token => "cc_1234", owner_id: user.id, owner_type: 'User', source: 'manual', status: 'subscribed'  )}

    it "should be subscribed when the user has a valid subscription" do
      user.subscribed?.should == true
    end

    it "should not be subscribed when the user doesn't have a valid subscription" do
      subscription.valid_to = Time.now - 10.days
      subscription.save
      user.subscribed?.should == false
    end

    it "should not be subscribed when the user's subscription is empty" do
      Subscription.where(owner_id: user.id, owner_type: "User").destroy_all
      user.subscribed?.should == false
    end
  end
end
