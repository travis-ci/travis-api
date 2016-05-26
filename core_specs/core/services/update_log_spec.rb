require 'spec_helper'

describe Travis::Services::UpdateLog do
  include Travis::Testing::Stubs

  let(:service) { described_class.new(user, params) }
  let(:params)  { { id: log.id, archived_at: Time.now, archive_verified: true } }

  before :each do
    log.stubs(:update_attributes).returns(true)
    service.stubs(:run_service).with(:find_log, id: log.id).returns(log)
  end

  it 'updates the log' do
    log.expects(:update_attributes).with(archived_at: params[:archived_at], archive_verified: true)
    service.run
  end


  describe 'the instrument' do
    let(:publisher) { Travis::Notification::Publisher::Memory.new }
    let(:event)     { publisher.events.last }

    before :each do
      Travis::Notification.publishers.replace([publisher])
    end

    it 'publishes a event' do
      service.run
      event.should publish_instrumentation_event(
        event: 'travis.services.update_log.run:completed',
        message: "Travis::Services::UpdateLog#run:completed for #<Log id=#{log.id}> params=#{params}",
        result: true
      )
    end
  end
end
