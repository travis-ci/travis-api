describe Travis::API::V3::Models::Branch do
  let!(:subject) { FactoryGirl.create(:branch) }

  it "cron should be deleted when the related branch is deleted" do
    cron = FactoryGirl.create(:cron, branch: subject)
    subject.destroy
    Travis::API::V3::Models::Cron.find_by_id(cron.id).should be nil
  end
end
