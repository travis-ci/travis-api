describe Travis::API::V3::Metrics do
  class TestProcessor
    attr_reader :times, :marks, :queue

    def initialize
      @queue = []
      @times = []
      @marks = []
    end

    def time(*args)
      times << args
    end

    def mark(name)
      marks << name
    end
  end

  subject(:processor) { TestProcessor.new                                }
  let(:metric)        { described_class.new(processor, time: Time.at(0)) }

  before do
    metric.name_after(Travis::API::V3::Services::Branch::Find)
    metric.tick(:example,       time: Time.at(10))
    metric.tick(:other_example, time: Time.at(15))
    metric.success(time: Time.at(25))
    metric.process(processor)
  end

  its(:queue) { is_expected.to eq [metric] }

  its(:times) { is_expected.to eq [
    ["branch.find.example",       10.0],
    ["branch.find.other_example", 5.0],
    ["branch.find.overall",       25.0]
  ] }

  its(:marks) { is_expected.to eq ["status.200", "branch.find.success"] }
end
