require 'spec_helper'

describe Travis::Services::FindJobs do
  include Support::ActiveRecord

  let(:repo)    { Factory(:repository) }
  let!(:job)    { Factory(:test, :repository => repo, :state => :created, :queue => 'builds.linux') }
  let(:service) { described_class.new(stub('user'), params) }

  attr_reader :params

  describe 'run' do
    it 'finds jobs on the given queue' do
      @params = { :queue => 'builds.linux' }
      service.run.should include(job)
    end

    it 'does not find jobs on other queues' do
      @params = { :queue => 'builds.nodejs' }
      service.run.should_not include(job)
    end

    it 'finds jobs by a given list of ids' do
      @params = { :ids => [job.id] }
      service.run.should == [job]
    end

    it 'finds jobs by state' do
      build = Factory(:build)

      Job::Test.destroy_all

      started = Factory(:test, :state => :started, :source => build)
      passed  = Factory(:test, :state => :passed,  :source => build)
      created = Factory(:test, :state => :created, :source => build)

      @params = { :state => ['created', 'passed'] }
      service.run.sort_by(&:id).should == [created, passed].sort_by(&:id)
    end

    it 'finds jobs that are about to run without any args' do
      build = Factory(:build)

      Job::Test.destroy_all

      started = Factory(:test, :state => :started, :source => build)
      queued = Factory(:test, :state => :queued, :source => build)
      passed  = Factory(:test, :state => :passed,  :source => build)
      created = Factory(:test, :state => :created, :source => build)
      received = Factory(:test, :state => :received, :source => build)

      @params = {}
      service.run.sort_by(&:id).should == [started, queued, created, received].sort_by(&:id)
    end
  end

  describe 'updated_at' do
    it 'returns the latest updated_at time' do
      pending 'rack cache is disabled, so not much need for caching now'

      @params = { :queue => 'builds.linux' }
      Job.delete_all
      Factory(:test, :repository => repo, :state => :queued, :queue => 'build.common', :updated_at => Time.now - 1.hour)
      Factory(:test, :repository => repo, :state => :queued, :queue => 'build.common', :updated_at => Time.now)
      service.updated_at.to_s.should == Time.now.to_s
    end
  end
end
