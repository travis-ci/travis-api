require 'spec_helper'
require 'travis/services/assembla_notify_service'

RSpec.describe Travis::Services::AssemblaNotifyService do
  let(:payload) { { 'action' => 'restrict', 'object' => 'tool', 'id' => '12345' } }
  let(:service) { described_class.new(payload) }
  let(:vcs_repository) { instance_double(Travis::RemoteVCS::Repository) }
  let(:vcs_organization) { instance_double(Travis::RemoteVCS::Organization) }

  before do
    allow(Travis::RemoteVCS::Repository).to receive(:new).and_return(vcs_repository)
    allow(vcs_repository).to receive(:destroy).with(any_args)
    allow(vcs_repository).to receive(:restore)
    allow(Travis::RemoteVCS::Organization).to receive(:new).and_return(vcs_organization)
    allow(vcs_organization).to receive(:destroy)
    allow(vcs_organization).to receive(:restore)
    allow(Travis.logger).to receive(:error)
  end

  describe '#run' do
    context 'with a valid payload for tool restriction' do
      it 'calls destroy on the vcs_repository' do
        expect(vcs_repository).to receive(:destroy).with(repository_id: '12345', vcs_type: 'AssemblaRepository')
        service.run
      end
    end

    context 'with a valid payload for tool restoration' do
      let(:payload) { { 'action' => 'restore', 'object' => 'tool', 'id' => '12345' } }
      it 'calls restore on the vcs_repository' do
        expect(vcs_repository).to receive(:restore).with(repository_id: '12345')
        service.run
      end
    end

    context 'with a valid payload for space restriction' do
      let(:payload) { { 'action' => 'restrict', 'object' => 'space', 'id' => '67890' } }

      it 'calls destroy on the vcs_organization' do
        expect(vcs_organization).to receive(:destroy).with(org_id: '67890')
        service.run
      end
    end

    context 'with a valid payload for space restoration' do
      let(:payload) { { 'action' => 'restore', 'object' => 'space', 'id' => '67890' } }

      it 'calls restore on the vcs_organization' do
        expect(vcs_organization).to receive(:restore).with(org_id: '67890')
        service.run
      end
    end

    context 'with an invalid object type' do
      let(:payload) { { 'action' => 'restrict', 'object' => 'repository', 'id' => '12345' } }

      it 'returns false and logs an error' do
        expect(service.run).to be_falsey
        expect(Travis.logger).to have_received(:error).with("Invalid object type: repository. Allowed objects: space, tool")
      end
    end

    context 'with an invalid action type' do
      let(:payload) { { 'action' => 'modify', 'object' => 'tool', 'id' => '12345' } }

      it 'returns false and logs an error' do
        expect(service.run).to be_falsey
        expect(Travis.logger).to have_received(:error).with("Invalid action: modify. Allowed actions: restrict, restore")
      end
    end

    context 'with an unsupported object type for an action' do
      before do
        stub_const("Travis::Services::AssemblaNotifyService::VALID_OBJECTS", %w[space tool unsupported])
      end
      let(:payload) { { 'action' => 'restrict', 'object' => 'unsupported', 'id' => '12345' } }

      it 'returns false without logging an error for the action' do
        expect(service.run).to be_falsey
        expect(vcs_repository).not_to receive(:destroy)
        expect(vcs_repository).not_to receive(:restore)
        expect(vcs_organization).not_to receive(:destroy)
        expect(vcs_organization).not_to receive(:restore)
      end
    end
  end
end
