require 'spec_helper'

RSpec::Matchers.define :eq_datetime do |*expected|
  match do |actual|
    actual.to_i == DateTime.new(*expected).to_i
  end
end

describe Travis::API::V3::Models::Cron do
  let(:subject) { FactoryBot.create(:cron, branch_id: FactoryBot.create(:branch).id) }

  let!(:scheduler_interval) { Travis::API::V3::Models::Cron::SCHEDULER_INTERVAL + 1.minute }

  shared_examples_for "cron is deactivated" do
    before { subject.enqueue }
    it { expect(subject.active?).to be_falsey }
  end

  describe "scheduled scope" do
    it "collects all upcoming cron jobs" do
      cron1 = FactoryBot.create(:cron)
      cron2 = FactoryBot.create(:cron)

      cron2.update_attribute(:next_run, 2.hours.from_now)
      Timecop.travel(scheduler_interval.from_now)
      expect(Travis::API::V3::Models::Cron.scheduled.count).to eql 1
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
      expect(subject.next_run.to_i).to eql 5.minutes.from_now.utc.to_i
    end
  end

  context "when last_run is not set" do
    context "and from: is not passed" do
      it "sets the next_run from now" do
        subject.schedule_next_build
        expect(subject.next_run).to be_within(1.second).of DateTime.now + 1.day
      end
    end
    context "and from: is passed" do
      it "sets the next_run from from:" do
        subject.schedule_next_build(from: DateTime.now + 3.day)
        expect(subject.next_run).to be_within(1.second).of DateTime.now + 4.day
      end
    end

    context "and from: is more than one interval in the past" do
      it "ensures that the next_run is in the future" do
        subject.schedule_next_build(from: DateTime.now - 2.day)
        expect(subject.next_run).to be >= DateTime.now
      end
    end
  end

  describe "enqueue" do
    it "enqueues the cron" do
      expect_any_instance_of(Sidekiq::Client).to receive(:push).once
      subject.enqueue
    end

    it "set the last_run time to now" do
      subject.enqueue
      expect(subject.last_run).to be_within(1.second).of DateTime.now.utc
    end

    it "schedules the next run" do
      subject.enqueue
      expect(subject.next_run).to be_within(1.second).of DateTime.now.utc + 1.day
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
      let(:cron) { FactoryBot.create(:cron, branch_id: FactoryBot.create(:branch).id, dont_run_if_recent_build_exists: true) }
      it "needs_new_build? returns true" do
        expect(cron.needs_new_build?).to be_truthy
      end
    end

    context "when last build within last 24h has no started_at" do
      let(:build) { FactoryBot.create(:v3_build, started_at: nil, number: 100) }
      let(:cron) { FactoryBot.create(:cron, branch_id: FactoryBot.create(:branch, last_build: build).id, dont_run_if_recent_build_exists: true) }
      it "needs_new_build? returns true" do
        expect(cron.needs_new_build?).to be_truthy
      end
    end

    context "when there was a build in the last 24h" do
      let(:cron) { FactoryBot.create(:cron, branch_id: FactoryBot.create(:branch, last_build: FactoryBot.create(:v3_build, number: 200)).id, dont_run_if_recent_build_exists: true) }

      it "needs_new_build? returns false" do
        expect(cron.needs_new_build?).to be_falsey
      end
    end
  end

  describe 'needs_new_build' do
    let(:repo)   { FactoryBot.create(:repository_without_last_build, active: active) }
    let(:branch) { FactoryBot.create(:branch, repository_id: repo.id) }
    let(:cron)   { FactoryBot.create(:cron, branch_id: branch.id) }

    describe 'given the repository is active' do
      let(:active) { true }
      it { expect(cron.enqueue).to eq true }
    end

    describe 'given the repository is active' do
      let(:active) { false }
      it { expect(cron.enqueue).to eq false }
      it "logs the reason" do
        expect(Travis.logger).to receive(:info).with("Removing cron #{cron.id} because the associated #{Travis::API::V3::Models::Cron::REPO_IS_INACTIVE}")
        cron.enqueue
      end
    end
  end

  context "when repo ownership is transferred" do
    it "enqueues a cron for the repo with the new owner" do
      subject.branch.repository.update_attribute(:owner, FactoryBot.create(:user, name: "Yoda", login: "yoda", email: "yoda@yoda.com"))
      subject.branch.repository.update_attribute(:owner_type, 'User')
      expect_any_instance_of(Sidekiq::Client).to receive(:push).once
      subject.enqueue
    end
  end
end
