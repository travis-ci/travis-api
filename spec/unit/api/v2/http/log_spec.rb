require 'spec_helper'

describe Travis::Api::V2::Http::Log do
  include Travis::Testing::Stubs

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
      ])
    end
    let(:data) { described_class.new(log, chunked: true).data }

    it 'returns ordered parts' do
      data['log']['parts'].should == [
        { 'id' => 1, 'number' => 1, 'content' => 'foo', 'final' => false },
        { 'id' => 2, 'number' => 2, 'content' => 'bar', 'final' => true }
      ]
    end
  end
end
