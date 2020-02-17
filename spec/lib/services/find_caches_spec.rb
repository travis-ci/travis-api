describe Travis::Services::FindCaches do
  include Support::S3, Support::GCS

  let(:user) { User.first || FactoryBot.create(:user) }
  let(:service) { described_class.new(user, params) }
  let(:repo) { FactoryBot.create(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let(:cache_options) {{ s3: { bucket_name: '' , access_key_id: '', secret_access_key: ''} }}
  let(:result) { service.run }
  subject { result }

  before :each do
    Travis.config.roles = {}
    Travis.config.cache_options = cache_options
    user.permissions.create(repository_id: repo.id, push: true)
  end

  describe 'given a repository_id' do
    let(:params) {{ repository_id: repo.id }}

    describe 'without any caches' do
      it { is_expected.to eq [] }
    end

    describe 'with caches' do
      before do
        s3_bucket << "#{repo.github_id}/master/cache--example1.tbz"
        s3_bucket << "#{repo.github_id}/other/cache--example2.tbz"
        s3_bucket << "#{repo.github_id.succ}/master/cache--example3.tbz"
      end

      its(:size) { is_expected.to eq 2 }

      describe 'the cache instances' do
        subject { result.first }
        its(:slug)       { is_expected.to eq 'cache--example1' }
        its(:branch)     { is_expected.to eq 'master' }
        its(:repository) { is_expected.to eq repo }
        its(:size)       { is_expected.to eq 0 }
      end

      describe 'with branch' do
        let(:params) {{ repository_id: repo.id, branch: 'other' }}
        its(:size) { is_expected.to eq 1 }
      end

      describe 'with match' do
        let(:params) {{ repository_id: repo.id, match: 'example1' }}
        its(:size) { is_expected.to eq 1 }
      end

      it 'returns nil if user does not have push permission' do
        user.permissions.first.update(push: false)
        expect{ service.run }.to raise_error Travis::AuthorizationDenied
      end

      describe 'without s3 credentials' do
        let(:cache_options) {{ }}
        before { expect(service.logger).to receive(:warn).with("[services:find-caches] cache settings incomplete") }
        it { is_expected.to eq [] }
      end

      describe 'with multiple buckets' do
        let(:cache_options) { {
          s3: { bucket_name: '', access_key_id: '', secret_access_key: '' }
        } }
        its(:size) do
          skip "this isn't valid anymore we don't use multiple buckets"
          is_expected.to eq 4
        end
      end
    end

    context 'with GCS configuration' do
      let(:cache_options) { { gcs: { bucket_name: '', json_key: '' } } }
      its(:size) { is_expected.to eq 0 }
    end
  end
end
