require 'rails_helper'

RSpec.describe Job, type: :model do
  describe '.from_repositories' do
    it 'gets all jobs belonging to a list of repositories' do
      repositories = create_list(:repository, 2)
      repository = create :repository

      create_list(:job, 5, repository: repositories[0])
      create_list(:job, 5, repository: repositories[1])
      job = create(:job, repository: repository)

      expect(Job.all.count).to eql 11
      expect(Job.from_repositories(repositories).count).to eql 10
      expect(Job.from_repositories(repositories)).not_to include job
    end
  end

  describe '.not_finished' do
    it 'gets only jobs with state started received queued and created' do
      create_list(:job, 5)
      create(:job, state: 'started')
      create(:job, state: 'received')
      create(:job, state: 'queued')
      create(:job, state: 'created')
      finished_job = create(:job, state: 'finished')

      expect(Job.all.count).to eql 10
      expect(Job.not_finished.count).to eql 4
      expect(Job.not_finished).not_to include finished_job
    end
  end
end
