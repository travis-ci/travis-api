require 'rails_helper'

RSpec.describe Job, type: :model do
  describe '.from_repositories' do
    let!(:relevant_repos) { create_list(:repository, 2) }
    let!(:other_repo)     { create :repository }
    let!(:relevant_jobs)  { create_list(:job, 5, repository: relevant_repos[0]);
                            create_list(:job, 5, repository: relevant_repos[1]) }
    let!(:other_job)      { create(:job, repository: other_repo) }

    it 'gets all jobs belonging to a list of repositories' do
      expect(Job.all.count).to eql 11
      expect(Job.from_repositories(relevant_repos).count).to eql 10
    end

    it 'doesn\'t get jobs that don\'t belong to owner\'s repositories' do
      expect(Job.from_repositories(relevant_repos)).not_to include other_job
    end
  end

  describe '.not_finished' do
    let!(:finished_job) { create(:job, state: 'finished') }
    let!(:queued_job)   { create(:job, state: 'queued') }
    let!(:started_job)  { create(:job, state: 'started') }
    let!(:received_job) { create(:job, state: 'received') }
    let!(:created_job)  { create(:job, state: 'created') }

    it 'gets only jobs with state started received queued and created' do
      expect(Job.all.count).to eql 5
      expect(Job.not_finished.count).to eql 4
    end

    it 'doesn\'t get finished job' do
      expect(Job.not_finished).not_to include finished_job
    end

    it 'sorts the jobs in order of started received queued and created' do
      expect(Job.not_finished).to eql [started_job, received_job, queued_job, created_job]
    end
  end
end
