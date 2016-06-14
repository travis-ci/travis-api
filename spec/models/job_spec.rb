require 'rails_helper'

RSpec.describe Job, type: :model do
  describe '.from_repositories' do
    it 'gets all jobs belonging to a list of repositories' do
      owner_repositories = create_list(:repository, 2)
      other_repository = create :repository

      create_list(:job, 5, repository: owner_repositories[0])
      create_list(:job, 5, repository: owner_repositories[1])
      other_job = create(:job, repository: other_repository)

      expect(Job.all.count).to eql 11
      expect(Job.from_repositories(owner_repositories).count).to eql 10
      expect(Job.from_repositories(owner_repositories)).not_to include other_job
    end
  end

  describe '.not_finished' do
    let!(:finished_job) {create(:job, state: 'finished')}

    it 'gets only jobs with state started received queued and created' do
      create(:job, state: 'started')
      create(:job, state: 'received')
      create(:job, state: 'queued')
      create(:job, state: 'created')

      expect(Job.all.count).to eql 5
      expect(Job.not_finished.count).to eql 4
      expect(Job.not_finished).not_to include finished_job
    end
  end
end
