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
    let!(:finished_job) { create(:finished_job) }
    let!(:queued_job)   { create(:queued_job) }
    let!(:started_job)  { create(:started_job) }
    let!(:received_job) { create(:received_job) }
    let!(:created_job)  { create(:created_job) }

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
    let!(:passed_job)   { create(:passed_job) }
    let!(:failed_job)   { create(:failed_job) }
    let!(:started_job)  { create(:started_job) }
    let!(:canceled_job) { create(:canceled_job) }
    let!(:errored_job)  { create(:errored_job) }


    it 'gets only jobs with state passed failed canceled and errored' do
      expect(Job.all.count).to eql 5
      expect(Job.finished.count).to eql 4
    end

    it 'doesn\'t get started job' do
      expect(Job.finished).not_to include started_job
    end

    it 'sorts the jobs in order of id DESC' do
      expect(Job.finished.map(&:id)).to eql Job.finished.map(&:id).sort { |x,y| y <=> x }
    end
  end

  describe '#duration' do
    let(:finished_job) { create(:finished_job) }
    let(:started_job) { create(:started_job) }

    context 'job is finished' do
      it 'gives the duration in seconds' do
        expect(finished_job.duration).to eql 188.0
      end
    end

    context 'job is not finished' do
      it 'returns nil' do
        expect(started_job.duration).to be nil
      end
    end
  end

  describe '#next' do
    let!(:build)          { create(:build) }
    let!(:other_build)    { create(:build) }
    let!(:job)            { create(:job, build: build, id: 4) }
    let!(:next_job)       { create(:job, build: build, id: 6) }
    let!(:unrelated_job)  { create(:job, build: other_build, id: 5) }
    let!(:unrelated_job2) { create(:job, build: other_build, id: 7) }

    it 'finds next job from the same build' do
      expect(job.next).to eql next_job
      expect(job.next.build).to eql build
    end

    it 'returns nil if there is no next job from the same build' do
      expect(next_job.next).to eql nil
    end
  end

  describe '#previous' do
    let!(:build)          { create(:build) }
    let!(:other_build)    { create(:build) }
    let!(:job)            { create(:job, build: build, id: 4) }
    let!(:previous_job)   { create(:job, build: build, id: 2) }
    let!(:unrelated_job)  { create(:job, build: other_build, id: 3) }
    let!(:unrelated_job2) { create(:job, build: other_build, id: 1) }

    it 'finds previous job from the same build' do
      expect(job.previous).to eql previous_job
      expect(job.previous.build).to eql build
    end

    it 'returns nil if there is no previous job from the same build' do
      expect(previous_job.previous).to eql nil
    end
  end
end
