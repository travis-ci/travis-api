describe Travis::Enqueue::Services::RestartModel do
  let(:owner) { FactoryBot.create(:user) }
  let(:repository) { FactoryBot.create(:repository, owner: owner) }
  let(:job) { FactoryBot.create(:job, repository: repository, state: 'canceled') }
  let(:user) { FactoryBot.create(:user) }
  let(:subscription) { nil }

  let(:service) { Travis::Enqueue::Services::RestartModel.new(user, { job_id: job.id }) }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  before do
    Travis.config.billing.url = 'http://localhost:9292/'
    Travis.config.billing.auth_key = 'secret'
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

    context 'when owner active plan' do
      before do
        stub_request(:post, /http:\/\/localhost:9292\/(users|organizations)\/(.+)\/authorize_build/).to_return(
          body: MultiJson.dump(allowed: true, rejection_code: nil)
        )
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
              let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
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
              let(:authorization) { { 'permissions' => ['repository_settings_read'] } }
              before { owner.memberships.create(user: user, build_permission: false) }

              include_examples 'does not restart the job'
            end
          end
        end
      end
    end

    context 'when customer does not have active plan' do
      before do
        stub_request(:post, /http:\/\/localhost:9292\/(users|organizations)\/(.+)\/authorize_build/)
          .to_return(status: 404, body: JSON.dump(error: 'Not Found'))
      end

      context 'when customer has no old subscription' do
        include_examples 'does not restart the job'
      end

      context 'when customer has an old active subscription' do
        before do
          repository.permissions.create(user: user, build: true)
          FactoryBot.create(:valid_stripe_subs, owner: owner)
        end

        include_examples 'restarts the job'
      end

      context 'when customer has an old canceled subscription' do
        let(:subscription) { FactoryBot.create(:canceled_stripe_subs, owner: owner) }

        include_examples 'does not restart the job'
      end

      context 'when customer belongs to a group' do
        let(:uuid) { SecureRandom.uuid }
        let!(:travis) { FactoryBot.create(:org, login: 'travis') }
        let!(:john)  { FactoryBot.create(:user, login: 'john') }
        let!(:doe)   { FactoryBot.create(:user, login: 'doe')  }
        before do
          repository.permissions.create(user: user, build: true)
          FactoryBot.create(:valid_stripe_subs, owner: john)
          OwnerGroup.create(uuid: uuid, owner: owner)
          OwnerGroup.create(uuid: uuid, owner: john)
          OwnerGroup.create(uuid: uuid, owner: doe)
        end

        include_examples 'restarts the job'
      end

    end
  end
end
