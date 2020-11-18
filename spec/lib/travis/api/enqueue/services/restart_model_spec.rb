describe Travis::Enqueue::Services::RestartModel do
  let(:owner) { FactoryBot.create(:user) }
  let(:repository) { FactoryBot.create(:repository, owner: owner) }
  let(:job) { FactoryBot.create(:job, repository: repository, state: 'canceled') }
  let(:user) { FactoryBot.create(:user) }

  let(:service) { Travis::Enqueue::Services::RestartModel.new(user, { job_id: job.id }) }

  before do
    Travis.config.billing.url = 'http://localhost:9292/'
    Travis.config.billing.auth_key = 'secret'

    stub_request(:post, /http:\/\/localhost:9292\/(users|organizations)\/(.+)\/authorize_build/).to_return(
      body: MultiJson.dump(allowed: true, rejection_code: nil)
    )
  end

  after do
    Travis.config.billing.url = nil
    Travis.config.billing.auth_key = nil
  end

  describe 'push' do
    let(:payload) { { id: job.id, user_id: user.id } }

    subject { service.push('job:restart', payload) }

    shared_examples 'restarts the job' do
      it do
        expect(subject.value).to eq({ id: job.id, user_id: user.id })
        expect(subject.error).to eq(nil)
      end
    end

    shared_examples 'does not restart the job' do
      it do
        expect(subject.value).to eq(nil)
        expect(subject.error).to eq('restart failed')
      end
    end

    context 'build permissions' do
      context 'when owner is a user' do
        context 'on repo level' do
          context 'when value is nil' do
            before { repository.permissions.create(user: user, build: nil) }

            include_examples 'restarts the job'
          end

          context 'when value is true' do
            before { repository.permissions.create(user: user, build: true) }

            include_examples 'restarts the job'
          end

          context 'when value is false' do
            before { repository.permissions.create(user: user, build: false) }

            include_examples 'does not restart the job'
          end
        end
      end

      context 'when owner is an organization' do
        let(:owner) { FactoryBot.create(:org) }

        before { repository.permissions.create(user: user, build: true) }

        context 'on organization level' do
          context 'when value is nil' do
            before { owner.memberships.create(user: user, build_permission: nil) }

            include_examples 'restarts the job'
          end

          context 'when value is true' do
            before { owner.memberships.create(user: user, build_permission: true) }

            include_examples 'restarts the job'
          end

          context 'when value is false' do
            before { owner.memberships.create(user: user, build_permission: false) }

            include_examples 'does not restart the job'
          end
        end
      end
    end
  end
end
