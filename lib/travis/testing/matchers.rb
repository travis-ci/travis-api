require 'hashdiff'

# RSpec::Matchers.define :serve_result_image do |result|
#   match do |request|
#     path = "#{Rails.root}/public/images/result/#{result}.png"
#     controller.expects(:send_file).with(path, { :type => 'image/png', :disposition => 'inline' }).once
#     request.call
#   end
# end

RSpec::Matchers.define :issue_queries do |count|
  match do |code|
    queries = call(code)

    failure_message do
      (["expected #{count} queries to be issued, but got #{queries.size}:"] + queries).join("\n\n")
    end

    queries.size == count
  end

  def call(code)
    queries = []
    ActiveSupport::Notifications.subscribe 'sql.active_record' do |name, start, finish, id, payload|
      queries << payload[:sql] unless payload[:sql] =~ /(?:ROLLBACK|pg_|BEGIN|COMMIT)/
    end
    code.call
    queries
  end

  def supports_block_expectations?
    true
  end
end

RSpec::Matchers.define :publish_instrumentation_event do |data|
  match do |event|
    non_matching = data.map { |key, value| [key, value, event[key]] unless event[key] == value }.compact
    expected_keys = [:uuid, :event, :started_at]
    missing_keys = expected_keys.select { |key| !event.key?(key) }

    failure_message do
      message =  "Expected a notification event to be published:\n\n\t#{event.inspect}\n\n"
      message << "Including:\n\n\t#{data.inspect}\n\n"

      non_matching.each do |key, expected, actual|
        message << "#{key.inspect} expected to be\n\n\t#{expected.inspect}\n\nbut was\n\n\t#{actual.inspect}\n\n"
      end

      message << "Expected #{missing_keys.map(&:inspect).join(', ')} to be present." if missing_keys.present?
      message
    end

    non_matching.empty? && missing_keys.empty?
  end
end

RSpec::Matchers.define :eql_json do |expected|
  match do |actual|
    actual == expected
  end

  failure_message do |actual|
    message = "expected to match JSON:\n"
    diff = Hashdiff.diff(expected, actual)
    diff_messages = diff.map do |type, path, a, b|
      if type == '-'
        "missing #{path} == #{a}"
      elsif type == '+'
        "extra entry #{path} == #{a}"
      elsif type == '~'
        "entries @#{path} do not match, expected: #{a}, actual: #{b}"
      else
        raise 'this should not happen'
      end
    end

    message << diff_messages.map { |m| "  #{m}" }.join("\n")
    message
  end

  description do
    "equal JSON"
  end
end


