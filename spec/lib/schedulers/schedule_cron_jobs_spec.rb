require "sentry-raven"
require "travis/api/app/schedulers/schedule_cron_jobs"

describe "ScheduleCronJobs" do
  let(:subject) { Travis::Api::App::Schedulers::ScheduleCronJobs.enqueue }

  before do
    Travis::Api::App::Schedulers::ScheduleCronJobs.stubs(:options).returns({
      strategy:      :redis,
      url: 'redis://localhost:6379',
      retries: 2
      })
  end

  let(:error) { StandardError.new("Konstantin broke all the thingz!") }
  let!(:scheduler_interval) { Travis::API::V3::Models::Cron::SCHEDULER_INTERVAL + 1.minute }

  describe "enqueue" do
    it 'continues running crons if one breaks' do
      cron1 = Factory(:cron)
      cron2 = Factory(:cron)
      Timecop.travel(scheduler_interval.from_now)

      Travis::API::V3::Models::Cron.any_instance.expects(:branch).raises(error)
      Raven.expects(:capture_exception).with(error, tags: {'cron_id' => cron1.id })


      Travis::API::V3::Models::Cron.any_instance.expects(:branch).raises(error)
      Raven.expects(:capture_exception).with(error, tags: {'cron_id' => cron2.id })

      subject

      Timecop.return
      cron1.destroy
      cron2.destroy
    end

    it "raises exception when enqueue method errors" do
      cron1 = Factory(:cron)
      Timecop.travel(scheduler_interval.from_now)

      Travis::API::V3::Models::Cron.any_instance.stubs(:enqueue).raises(error)

      Raven.expects(:capture_exception).with(error, tags: {'cron_id' => cron1.id })

      subject

      Timecop.return
      cron1.destroy
    end

    context "dont_run_if_recent_build_exists is true" do
      let!(:cron) { Factory(:cron, dont_run_if_recent_build_exists: true) }

      before { Timecop.freeze(DateTime.now) }

      context "no new build in the last 24h" do
        before do
          last_build = Factory.create(:build,
            repository_id: cron.branch.repository.id,
            finished_at: DateTime.now - 1.hour)
          cron.branch.update_attribute(:last_build_id, last_build.id)
          Timecop.travel(scheduler_interval.from_now)
        end

        after { Timecop.return }

        it "skips enqueuing a cron job" do
          Sidekiq::Client.any_instance.expects(:push).never
          subject
        end

        it "schedules the next cron job" do
          subject

          cron.reload
          expect(cron.next_run.to_i).to eql (Time.now.utc + 1.day).to_i
        end
      end
    end
  end
end
