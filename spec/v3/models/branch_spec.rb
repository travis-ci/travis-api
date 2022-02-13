describe Travis::API::V3::Models::Branch do
  #let!(:subject) { FactoryBot.create(:branch) }

  #it "cron should be deleted when the related branch is deleted" do
  #  cron = FactoryBot.create(:cron, branch: subject)
  #  subject.destroy
  #  expect(Travis::API::V3::Models::Cron.find_by_id(cron.id)).to be nil
  #end

  #it { puts Travis::API::V3::Models::Branch.all.where(name: 'master').first.builds.inspect; expect(Travis::API::V3::Models::Branch.all.where(name: 'master').first.builds.size).to eq(1) }

  # it { puts({ name: subject.name, repository_id: subject.repository_id}.inspect) ; puts Travis::API::V3::Models::Build.all.map { |el| { repository_id: el.repository_id, branch_name: el.branch_name } }.inspect; expect(subject.builds.size).to eq(1) }

  describe '#builds' do
    let(:repository) { FactoryBot.create(:v3_repository) }
    let!(:build) { FactoryBot.create(:v3_build, repository: repository, branch_name: 'name', event_type: 'push') }
    let(:branch) { FactoryBot.create(:branch, repository: repository, name: 'name') }

    it { expect(branch.builds.size).to eq(1) }
    #  it { br = repository.builds.to_a.first.branch; puts "repository_id: #{repository.id}, name: #{br.name}" ;expect(br.builds.to_sql).to eq(1) }
  end
end
