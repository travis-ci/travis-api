require 'rails_helper'

RSpec.describe StateDisplay do
  let(:klass) do
    Class.new do
      include StateDisplay

      def state
      end

      def canceled_at
        :canceled_time
      end

      def finished_at
        :finished_time
      end

      def started_at
        :started_time
      end

      def queued_at
        :queued_time
      end

      def created_at
        :created_time
      end
    end
  end

  subject { klass.new }

  describe '.state_time' do
    it 'returns nil if state is nil' do
      expect(subject.state_time).to be nil
    end

    it 'returns value for canceled_at if state is canceled' do
      allow(subject).to receive(:state) { 'canceled' }
      expect(subject.state_time).to eq(:canceled_time)
    end

    it 'returns value for finished_at if state is passed' do
      allow(subject).to receive(:state) { 'passed' }
      expect(subject.state_time).to eq(:finished_time)
    end

    it 'returns value for finished_at if state is errored' do
      allow(subject).to receive(:state) { 'errored' }
      expect(subject.state_time).to eq(:finished_time)
    end

    it 'returns value for finished_at if state is failed' do
      allow(subject).to receive(:state) { 'failed' }
      expect(subject.state_time).to eq(:finished_time)
    end

    it 'returns value for finished_at if state is finished' do
      allow(subject).to receive(:state) { 'finished' }
      expect(subject.state_time).to eq(:finished_time)
    end

    it 'returns value for started_at if state is started' do
      allow(subject).to receive(:state) { 'started' }
      expect(subject.state_time).to eq(:started_time)
    end

    it 'returns value for queued_at if state is queued' do
      allow(subject).to receive(:state) { 'queued' }
      expect(subject.state_time).to eq(:queued_time)
    end

    it 'returns value for created_at if state is created' do
      allow(subject).to receive(:state) { 'created' }
      expect(subject.state_time).to eq(:created_time)
    end
  end
end
