require "sentry-ruby"
require "travis/api/app/schedulers/schedule_cron_jobs"

describe "ScheduleCronJobs" do
  let(:subject) { Travis::Api::App::Schedulers::ScheduleCronJobs.enqueue }

  before do
    allow(Travis::Api::App::Schedulers::ScheduleCronJobs).to receive(:options).and_return({
      strategy:      :redis,
      url: 'redis://localhost:6379',
      retries: 2
      })
  end

  let(:error) { StandardError.new("Konstantin broke all the thingz!") }
  let!(:scheduler_interval) { Travis::API::V3::Models::Cron::SCHEDULER_INTERVAL + 1.minute }

  describe "enqueue" do
    it 'continues running crons if one breaks' do
      cron1 = FactoryBot.create(:cron)
      cron2 = FactoryBot.create(:cron)
      Timecop.travel(scheduler_interval.from_now)

      allow_any_instance_of(Travis::API::V3::Models::Cron).to receive(:branch).and_raise(error)
      expect(Sentry).to receive(:capture_exception).with(error, tags: {'cron_id' => cron1.id })
      expect(Sentry).to receive(:capture_exception).with(error, tags: {'cron_id' => cron2.id })

      subject

      Timecop.return
      Timecop.freeze(Time.now.utc)
      cron1.destroy
      cron2.destroy
    end

    it "raises exception when enqueue method errors" do
      cron1 = FactoryBot.create(:cron)
      Timecop.travel(scheduler_interval.from_now)

      expect_any_instance_of(Travis::API::V3::Models::Cron).to receive(:enqueue).and_raise(error)

      expect(Sentry).to receive(:capture_exception).with(error, tags: {'cron_id' => cron1.id })

      subject

      Timecop.return
      Timecop.freeze(Time.now.utc)
      cron1.destroy
    end

    context "dont_run_if_recent_build_exists is true" do
      let!(:cron) { FactoryBot.create(:cron, dont_run_if_recent_build_exists: true) }

      before { Timecop.freeze(DateTime.now) }

      context "no new build in the last 24h" do
        before do
          last_build = FactoryBot.create(:build,
            repository_id: cron.branch.repository.id,
            finished_at: DateTime.now - 1.hour)
          cron.branch.update_attribute(:last_build_id, last_build.id)
          Timecop.freeze(scheduler_interval.from_now)
        end

        after do
          Timecop.return
          Timecop.freeze(Time.now.utc)
        end

        it "skips enqueuing a cron job" do
          expect_any_instance_of(Sidekiq::Client).not_to receive(:push)
          subject
        end

        it "schedules the next cron job" do
          subject

          cron.reload
          expect(cron.next_run).to be_within(1.second).of Time.now.utc + 1.day
        end
      end
    end
  end
end
