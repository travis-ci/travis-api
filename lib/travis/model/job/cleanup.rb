# require 'active_support/concern'
#
# class Job
#
#   # Cleanup contains logic that is supposed to re-enqueue stalled jobs
#   # and finally finish them forcefully.
#   #
#   # This stuff is currently not used except when we occasionally
#   # re-enqueue jobs manually from the console.
#   module Cleanup
#     extend ActiveSupport::Concern
#
#     FORCE_FINISH_MESSAGE = <<-msg.strip
#       This job could not be processed and was forcefully finished.
#     msg
#
#     included do
#       class << self
#         def cleanup
#           stalled.each do |job|
#             job.requeueable? ? job.enqueue : job.force_finish
#           end
#         end
#
#         def stalled
#           unfinished.where('created_at < ?', Time.now.utc - Travis.config.jobs.retry.after)
#         end
#       end
#     end
#
#     def force_finish
#       append_log!("\n#{FORCE_FINISH_MESSAGE}") if respond_to?(:append_log!)
#       finish!(state: :errored, finished_at: Time.now.utc)
#     end
#
#     def requeueable?
#       false
#       # retries < Travis.config.jobs.retry.max_attempts
#     end
#   end
# end
