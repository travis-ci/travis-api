# frozen_string_literal: true

require 'rails_helper'

describe AuditTrailController do
  describe '#index' do
    it 'renders successfully' do
      get :index

      expect(response).to be_successful
      expect(response.body).to have_selector('ul.log-list')
    end

    context 'when there are different logs' do
      let(:message1) { %Q{level=info time=#{Time.now.iso8601} admin_id=1 admin_login=test message="Test message" arg1=val1} }
      let(:message2) { "<time>#{Time.now.iso8601}</time> some message" }

      before do
        Travis::DataStores.redis.lpush("admin-v2:logs", message1)
        Travis::DataStores.redis.lpush("admin-v2:logs", message2)
      end

      it 'renders successfully' do
        get :index

        expect(response).to be_successful
        expect(response.body).to have_selector('ul.log-list') do |ul|
          expect(ul).to have_selector('li') do |li|
            expect(li).to have_selector('a', href: user_path(1), content: 'test')
          end
          expect(ul).to have_selector('li') do |li|
            expect(li).to contain(message2)
          end
        end
      end
    end
  end
end
