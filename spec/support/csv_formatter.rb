require 'csv'
require 'rspec/core/formatters/base_formatter'

# $ bundle exec rspec spec/auth --require ./spec/support/csv_formatter.rb --format CsvFormatter

class CsvFormatter < RSpec::Core::Formatters::BaseFormatter
  COLS = %i(site version resource mode repo context method path status result comment)
  DESC = /^Auth (?<resource>[\w\/]+) .* (?<method>HEAD|GET|PUT|POST|DELETE) (?<path>[^ ]+) .*/

  def stop
    super
    @data = examples.map { |example| parse(example) }
  end

  def close
    output.write to_csv(@data)
    output.close if IO === output && output != $stdout
  end

  def parse(example)
    str, meta, result = example.full_description, example.metadata, example.execution_result[:status]
    match = str.match(DESC)
    [
      meta[:site],
      meta[:api_version],
      match[:resource],
      meta[:mode],
      meta[:repo],
      example.description,
      match[:method],
      match[:path],
      status(example),
      result,
      comment(example)
    ]
  end

  def to_csv(data)
    CSV.generate do |csv|
      csv << COLS
      data.map { |row| csv << row }
    end
  end

  # RSpec auto-generates a description for the last matcher, but only if the
  # example does not have a description itself. If the description is set then
  # there's no way to access the last matcher within any RSpec formatter hook
  # anymore. So this parses the Ruby code instead.
  def status(example)
    code(example) =~ /should +eq +([\d]+)/ && $1.to_i
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
