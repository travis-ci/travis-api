require 'spec_helper'

RSpec::Matchers.define :eq_datetime do |*expected|
  match do |actual|
    actual.to_i == DateTime.new(*expected).to_i
  end
end

describe Travis::API::V3::Models::Cron do
  let(:subject) { Factory(:cron, branch_id: Factory(:branch).id) }

  let!(:scheduler_interval) { Travis::API::V3::Models::Cron::SCHEDULER_INTERVAL + 1.minute }

  shared_examples_for "cron is deactivated" do
    before { subject.enqueue }
    it { expect(subject.active?).to be_falsey }
  end

  describe "scheduled scope" do
    it "collects all upcoming cron jobs" do
      cron1 = Factory(:cron)
      cron2 = Factory(:cron)

      cron2.update_attribute(:next_run, 2.hours.from_now)
      Timecop.travel(scheduler_interval.from_now)
      Travis::API::V3::Models::Cron.scheduled.count.should eql 1
      Timecop.return
      cron1.destroy
      cron2.destroy
    end
  end

  describe "next build time is calculated correctly on year changes" do
    before do
      Timecop.return
      Timecop.travel(DateTime.new(2015, 12, 31, 16))
    end

    after do
      Timecop.return
      Timecop.freeze(Time.now.utc)
    end

    it "for daily builds" do
      subject.schedule_next_build(from: DateTime.now)
      expect(subject.next_run).to eq_datetime(2016, 1, 1, 16)
    end

    it "for weekly builds" do
      subject.interval = "weekly"
      subject.schedule_next_build(from: DateTime.now)
      expect(subject.next_run).to eq_datetime(2016, 1, 7, 16)
    end

    it "for monthly builds" do
      subject.interval = "monthly"
      subject.schedule_next_build(from: DateTime.now)
      expect(subject.next_run).to eq_datetime(2016, 1, 31, 16)
    end
  end

  context "for daily runs, when last_run is set" do
    it "sets the next_run correctly" do
      subject.last_run = 1.day.ago.utc + 5.minutes
      subject.schedule_next_build
      subject.next_run.to_i.should eql 5.minutes.from_now.utc.to_i
    end
  end

  context "when last_run is not set" do
    context "and from: is not passed" do
      it "sets the next_run from now" do
        subject.schedule_next_build
        subject.next_run.should be == DateTime.now + 1.day
      end
    end
    context "and from: is passed" do
      it "sets the next_run from from:" do
        subject.schedule_next_build(from: DateTime.now + 3.day)
        subject.next_run.should be == DateTime.now + 4.day
      end
    end

    context "and from: is more than one interval in the past" do
      it "ensures that the next_run is in the future" do
        subject.schedule_next_build(from: DateTime.now - 2.day)
        subject.next_run.should be >= DateTime.now
      end
    end
  end

  describe "enqueue" do
    it "enqueues the cron" do
      Sidekiq::Client.any_instance.expects(:push).once
      subject.enqueue
    end

    it "set the last_run time to now" do
      subject.enqueue
      subject.last_run.should be == DateTime.now.utc
    end

    it "schedules the next run" do
      subject.enqueue
      subject.next_run.should be == DateTime.now.utc + 1.day
    end

    context "when branch does not exist on github" do
      before { subject.branch.exists_on_github = false }
      include_examples "cron is deactivated"
    end

    context "when repo is no longer active" do
      before { subject.branch.repository.active = false }
      include_examples "cron is deactivated"
    end
  end

  context "when always_run? is false" do
    context "when no build has existed before running a cron build" do
      let(:cron) { Factory(:cron, branch_id: Factory(:branch).id, dont_run_if_recent_build_exists: true) }
      it "needs_new_build? returns true" do
        cron.needs_new_build?.should be_truthy
      end
    end

    context "when last build within last 24h has no started_at" do
      let(:build) { Factory(:v3_build, started_at: nil) }
      let(:cron) { Factory(:cron, branch_id: Factory(:branch, last_build: build).id, dont_run_if_recent_build_exists: true) }
      it "needs_new_build? returns true" do
        cron.needs_new_build?.should be_truthy
      end
    end

    context "when there was a build in the last 24h" do
      let(:cron) { Factory(:cron, branch_id: Factory(:branch, last_build: Factory(:v3_build)).id, dont_run_if_recent_build_exists: true) }

      it "needs_new_build? returns false" do
        cron.needs_new_build?.should be_falsey
      end
    end
  end

  context "when repo ownership is transferred" do
    it "enqueues a cron for the repo with the new owner" do
      subject.branch.repository.update_attribute(:owner, Factory(:user, name: "Yoda", login: "yoda", email: "yoda@yoda.com"))
      Sidekiq::Client.any_instance.expects(:push).once
      subject.enqueue
    end
  end
end
