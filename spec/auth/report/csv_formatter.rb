require 'csv'
require 'rspec/core/formatters/base_formatter'

# run auth specs with formatter, skip the first line:
#
# $ bundle exec rspec spec/auth --require ./spec/support/csv_formatter.rb --format CsvFormatter | tail -n +2

class CsvFormatter < RSpec::Core::Formatters::BaseFormatter
  COLS = %i(result version mode repo context method resource path status empty comment)
  PATH = /^(?<method>HEAD|GET|PUT|POST|DELETE) (?<path>.*)$/
  RESOURCE = /^v[\d\.]+ (?<resource>[\w]+)/

  def example_started(example)
    $stderr.puts example.full_description
    super
  end

  def stop
    super
    @data = examples.map { |example| parse(example) }
  rescue => e
    $stderr.puts e.message, e.backtrce
  end

  def close
    output.write to_csv(@data)
    output.close if IO === output && output != $stdout
  end

  def parse(example)
    return [] unless match = example.full_description.match(RESOURCE)
    resource = match[:resource]
    return [] unless match = example.example_group.description.match(PATH)
    method, path = match[:method], match[:path]
    meta, result = example.metadata, example.execution_result[:status]

    [
      result,
      meta[:api_version],
      meta[:mode],
      meta[:repo],
      example.description,
      method,
      resource,
      path,
      meta[:response].status,
      empty(example),
      comment(example)
    ]
  rescue => e
    $stderr.puts e.message, e.backtrace
    exit
  end

  def to_csv(data)
    CSV.generate do |csv|
      csv << COLS
      data.map { |row| csv << row }
    end
  end

  # # RSpec auto-generates a description for the last matcher, but only if the
  # # example does not have a description itself. If the description is set then
  # # there's no way to access the last matcher within any RSpec formatter hook
  # # anymore. So this parses the Ruby code instead.
  # def status(example)
  #   code(example) =~ /status: +([\d]+)/ && $1.to_i
  # end

  def empty(example)
    return unless str = code(example) =~ /empty: ([\w]+)/ && $1
    str == 'true' ? 'yes' : 'no'
  end

  def comment(example)
    code(example) =~ /# (.*)$/ && $1
  end

  def code(example)
    str = example.instance_variable_get(:@example_block).to_s
    path, line = str =~ /Proc:.*@(.*):(\d+)>/ && [$1, $2]
    fail unless path && line
    code = file(path)[line.to_i - 1]
  end

  def file(path)
    files[path] ||= File.read(path).split("\n")
  end

  def files
    @files ||= {}
  end
end
