require 'spec_helper'
require 'travis/services/assembla_notify_service'

RSpec.describe Travis::Services::AssemblaNotifyService do
  let(:payload) { { action: 'destroy', object: 'tool', id: '12345' } }
  let(:service) { described_class.new(payload) }
  let(:vcs_repository) { instance_double(Travis::RemoteVCS::Repository) }
  let(:vcs_organization) { instance_double(Travis::RemoteVCS::Organization) }

  before do
    allow(Travis::RemoteVCS::Repository).to receive(:new).and_return(vcs_repository)
    allow(vcs_repository).to receive(:destroy)
    allow(Travis::RemoteVCS::Organization).to receive(:new).and_return(vcs_organization)
    allow(vcs_organization).to receive(:destroy)
    allow(Travis.logger).to receive(:error)
  end

  describe '#run' do
    context 'with a valid payload for tool destruction' do
      it 'calls handle_tool_destruction' do
        expect(service).to receive(:handle_tool_destruction)
        service.run
      end
    end

    context 'with a valid payload for space destruction' do
      let(:payload) { { action: 'destroy', object: 'space', id: '67890' } }

      it 'calls handle_space_destruction' do
        expect(service).to receive(:handle_space_destruction)
        service.run
      end
    end

    context 'with an invalid object type' do
      let(:payload) { { action: 'destroy', object: 'repository', id: '12345' } }

      it 'returns an error' do
        result = service.run
        expect(result[:status]).to eq(400)
      end
    end

    context 'with an unsupported object type for destruction' do
      before do
        stub_const("Travis::Services::AssemblaNotifyService::VALID_OBJECTS", %w[space tool unsupported])
      end
      let(:payload) { { action: 'destroy', object: 'unsupported', id: '12345' } }

      it 'returns an error' do
        result = service.run
        expect(result[:status]).to eq(400)
      end
    end
  end

  describe '#handle_tool_destruction' do
    it 'destroys the repository using RemoteVCS' do
      expect(vcs_repository).to receive(:destroy).with(repository_id: '12345')
      service.send(:handle_tool_destruction)
    end

    context 'when RemoteVCS raises an error' do
      let(:error) { StandardError.new('VCS error') }

      before do
        allow(vcs_repository).to receive(:destroy).and_raise(error)
      end

      it 'logs the error' do
        expect(Travis.logger).to receive(:error).with('Failed to process Assembla tool destruction: VCS error')
        service.send(:handle_tool_destruction)
      end
    end
  end

  describe '#handle_space_destruction' do
    let(:payload) { { action: 'destroy', object: 'space', id: '67890' } }

    it 'destroys the organization using RemoteVCS' do
      expect(vcs_organization).to receive(:destroy).with(org_id: '67890')
      service.send(:handle_space_destruction)
    end

    context 'when RemoteVCS raises an error' do
      let(:error) { StandardError.new('VCS error') }

      before do
        allow(vcs_organization).to receive(:destroy).and_raise(error)
      end

      it 'logs the error' do
        expect(Travis.logger).to receive(:error).with('Failed to process Assembla organization destruction: VCS error')
        service.send(:handle_space_destruction)
      end
    end
  end
end
