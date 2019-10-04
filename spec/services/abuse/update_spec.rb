require 'rails_helper'

RSpec.describe Services::Abuse::Update do
  describe '#call' do
    let!(:admin) { create(:user) }

    %w[user organization].each do |klass|
      let(:offender) { create(klass) }

      subject { described_class.new(offender, params, admin) }

      context 'when previously trusted' do
        context 'when marked as offender' do
          let(:params) do
            {
              abuse: 'offenders',
              not_fishy: '0',
              reason: 'ABC'
            }
          end

          it "creates offender level abuse object for #{klass}" do
            expect { subject.call }
              .to change { ::Abuse.level_offender.where(reason: 'Updated manually, through admin: ABC').count }
              .by(1)
          end
        end

        context 'when marked as not_fishy' do
          let(:params) do
            {
              abuse: 'abuse_checks_enabled',
              not_fishy: '1',
              reason: ''
            }
          end

          it "creates not fishy level abuse object for #{klass}" do
            expect { subject.call }.to change { ::Abuse.level_not_fishy.count }.by(1)
          end
        end

        context 'when marked as fishy' do
          before { Travis::DataStores.redis.sadd('abuse:not_fishy', "#{offender.class.name}:#{offender.id}") }

          let(:offender) { create("#{klass}_with_abuse", level: ::Abuse::LEVEL_NOT_FISHY) }
          let(:params) do
            {
              abuse: 'abuse_checks_enabled',
              not_fishy: '0',
              reason: ''
            }
          end

          it "creates not fishy level abuse object for #{klass}" do
            expect { subject.call }.to change { ::Abuse.level_fishy.count }.by(1)
          end

          it 'removes not fishy level abuse' do
            expect { subject.call }.to change { ::Abuse.level_not_fishy.count }.by(-1)
          end
        end
      end

      context 'when previously offender' do
        before { Travis::DataStores.redis.sadd('abuse:offenders', "#{offender.class.name}:#{offender.id}") }

        let(:offender) { create("#{klass}_with_abuse", level: ::Abuse::LEVEL_OFFENDER) }

        context 'when marked as trusted and fishy' do
          let(:params) do
            {
              abuse: 'trusted',
              not_fishy: '0',
              reason: ''
            }
          end

          it "removes offender level abuse object for #{klass}" do
            expect { subject.call }.to change { ::Abuse.level_offender.count }.by(-1)
          end

          it 'does not create fishy abuse' do
            expect { subject.call }.not_to(change { ::Abuse.level_fishy.count })
          end
        end
      end
    end
  end
end
