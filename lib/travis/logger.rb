require 'travis/support/logger'

# do not display CACHE queries in the logs
# inspired by:
# * http://heliom.ca/blog/posts/disable-rails-cache-logging
#
# this is a bit of a hack, it would probably
# be nicer to put this in travis-support directly
module Travis
  class Logger
    alias_method :old_debug, :debug

    def debug(message, *args, &block)
      cleaned_message = uncolorize(message.dup).strip
      unless cleaned_message.start_with? 'CACHE'
        old_debug(message, *args, &block)
      end
    end

    def uncolorize(s)
      s.gsub(/\e\[([;\d]+)?m/, '')
    end
  end
end
