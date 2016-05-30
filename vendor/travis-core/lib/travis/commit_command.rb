module Travis
  class CommitCommand

    def initialize(message)
      @message = message.to_s
    end

    def skip?
      backwards_skip or command == 'skip'
    end

    private
    attr_reader :message

    def command
      message =~ /\[ci(?: |:)([\w ]*)\]/i && $1.downcase
    end

    def backwards_skip
      message =~ /\[skip\s+ci\]/i && true
    end
  end
end
