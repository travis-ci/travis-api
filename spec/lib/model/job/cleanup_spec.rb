# describe Job::Cleanup do
#   let(:job) { FactoryBot.create(:test) }
#
#   describe 'scopes' do
#     let! :jobs do
#       [ FactoryBot.create(:test, :state => :created,  :created_at => Time.now.utc - Travis.config.jobs.retry.after - 60),
#         FactoryBot.create(:test, :state => :started,  :created_at => Time.now.utc - Travis.config.jobs.retry.after - 120),
#         FactoryBot.create(:test, :state => :finished, :created_at => Time.now.utc - Travis.config.jobs.retry.after + 10) ]
#     end
#
#     describe :unfinished do
#       it 'finds unfinished jobs' do
#         # TODO fixme
#         # Job.unfinished.should == jobs[0, 2]
#         Job.unfinished.should include(jobs.first)
#         Job.unfinished.should include(jobs.second)
#       end
#     end
#
#     describe :stalled do
#       it 'finds stalled jobs' do
#         Job.stalled.order(:id).should == jobs[0, 2]
#       end
#     end
#   end
#
#   describe :force_finish do
#     # TODO @flippingbits, could you look into this?
#     xit 'appends a message to the log' do
#       job.force_finish
#       job.reload.log.content.should == "some log.\n#{Job::Requeuing::FORCE_FINISH_MESSAGE}"
#     end
#
#     it 'finishes the job' do
#       job.force_finish
#       job.finished?.should be_truthy
#     end
#   end
# end
#
#
