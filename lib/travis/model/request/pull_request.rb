class Request
  class PullRequest
    Try = Struct.new(:value) do
      def method_missing(*args, &block)
        Try.new(value.nil? ? nil : value.public_send(*args, &block))
      end
    end

    attr_reader :payload

    def initialize(payload)
      @payload = Try.new(Hashr.new(payload || {}))
    end

    def title
      payload.title.value
    end

    def number
      payload.number.value
    end

    def head_repo
      payload.head.repo.full_name.value
    end

    def base_repo
      payload.base.repo.full_name.value
    end

    def head_branch
      payload.head.ref.value
    end

    def base_branch
      payload.base.ref.value
    end
  end
end
