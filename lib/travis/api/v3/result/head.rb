module Travis::API::V3
  class Result::Head < Result
    def render(*)
      ''.freeze
    end
  end
end
