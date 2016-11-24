describe Travis::API::V3::Models::Branch do
  let!(:subject) { Factory(:branch) }

  it "cron should be deleted when the related branch is deleted" do
    cron = Factory(:cron, branch: subject)
    subject.destroy
    Travis::API::V3::Models::Cron.find_by_id(cron.id).should be nil
  end
end
