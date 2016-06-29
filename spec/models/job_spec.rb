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

  describe '.finished' do
    let!(:passed_job)   { create(:job, state: 'passed') }
    let!(:finished_job) { create(:job, state: 'finished') }
    let!(:failed_job)   { create(:job, state: 'failed') }
    let!(:started_job)  { create(:job, state: 'started') }
    let!(:canceled_job) { create(:job, state: 'canceled') }
    let!(:errored_job)  { create(:job, state: 'errored') }


    it 'gets only jobs with state passed failed finished canceled and errored' do
      expect(Job.all.count).to eql 6
      expect(Job.finished.count).to eql 5
    end

    it 'doesn\'t get started job' do
      expect(Job.finished).not_to include started_job
    end

    it 'sorts the jobs in order of id DESC' do
      expect(Job.finished.map(&:id)).to eql Job.finished.map(&:id).sort { |x,y| y <=> x }
    end
  end
end
