# require 'spec_helper'
#
# describe Job::Cleanup do
#   include Support::ActiveRecord
#
#   let(:job) { Factory(:test) }
#
#   describe 'scopes' do
#     let! :jobs do
#       [ Factory(:test, :state => :created,  :created_at => Time.now.utc - Travis.config.jobs.retry.after - 60),
#         Factory(:test, :state => :started,  :created_at => Time.now.utc - Travis.config.jobs.retry.after - 120),
#         Factory(:test, :state => :finished, :created_at => Time.now.utc - Travis.config.jobs.retry.after + 10) ]
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
#       job.reload.log.content.should == "some log.\n#{Job::Requeueing::FORCE_FINISH_MESSAGE}"
#     end
#
#     it 'finishes the job' do
#       job.force_finish
#       job.finished?.should be_true
#     end
#   end
# end
#
#
