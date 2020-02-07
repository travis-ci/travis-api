describe Travis::API::V3::Models::Branch do
  let!(:subject) { FactoryBot.create(:branch) }

  it "cron should be deleted when the related branch is deleted" do
    cron = FactoryBot.create(:cron, branch: subject)
    subject.destroy
    Travis::API::V3::Models::Cron.find_by_id(cron.id).should be nil
  end
end
