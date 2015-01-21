require 'spec_helper'

describe Travis::Api::V2::Http::Log do
  include Travis::Testing::Stubs

  let(:log) {
    stub_log(removed_at: false)
  }
  let(:data) { described_class.new(log).data }

  it 'log' do
    data['log'].should == {
      'id' => 1,
      'job_id' => 1,
      'type' => 'Log',
      'body' => 'the test log'
    }
  end

  describe 'chunked log' do
    let(:log) do
      stub_log(parts: [
        stub_log_part(id: 2, number: 2, content: 'bar', final: true),
        stub_log_part(id: 1, number: 1, content: 'foo')
      ], removed_at: false)
    end
    let(:data) { described_class.new(log, chunked: true).data }

    it 'returns ordered parts' do
      data['log']['parts'].should == [
        { 'id' => 1, 'number' => 1, 'content' => 'foo', 'final' => false },
        { 'id' => 2, 'number' => 2, 'content' => 'bar', 'final' => true }
      ]
    end

    describe "with parts numbers specified" do
      let(:data) { described_class.new(log, 'part_numbers' => "1,3", chunked: true).data }
      it 'returns only requested parts' do
        parts = log.parts.find_all { |p| p.number == 1 }
        log.parts.expects(:where).with(number: [1, 3]).returns(parts)

        data['log']['parts'].should == [{ 'id' => 1, 'number' => 1, 'content' => 'foo', 'final' => false }]
      end
    end
  end
end
