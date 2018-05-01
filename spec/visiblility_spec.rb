describe 'visibilty', set_app: true do
  let(:repo)     { Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:requests) { repo.requests.order(:id) }
  let(:builds)   { repo.builds.order(:id) }
  let(:jobs)     { Job.where(repository_id: repo.id).order(:id) }
  let(:response) { send(method, path, {}, { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2.1+json' }) }
  let(:status)   { response.status }
  let(:body)     { JSON.parse(response.body).deep_symbolize_keys }

  before { repo.update_attributes(private: false) }
  before { requests.update_all(private: true) }
  before { builds.update_all(private: true) }
  before { jobs.update_all(private: true) }
  before { requests[0].update_attributes(private: false) }
  before { builds[0].update_attributes(private: false) }
  before { jobs[0].update_attributes(private: false) }

  let(:public_request)  { requests[0] }
  let(:public_build)    { builds[0] }
  let(:public_job)      { jobs[0] }
  let(:private_request) { requests[2] }
  let(:private_build)   { builds[2] }
  let(:private_job)     { jobs[2] }

  before { Travis.config.host = 'travis-ci.com' }
  before { Travis.config.public_mode = true }

  before { stub_request(:get, %r(logs/#{public_job.id}\?by=job_id)).to_return(status: 200, body: %({"job_id": #{public_job.id} })) }
  before { stub_request(:get, %r(logs/1\?by=id)).to_return(status: 200, body: %({"job_id": #{public_job.id} })) }
  before { stub_request(:get, %r(logs/2\?by=id)).to_return(status: 200, body: %({"job_id": #{private_job.id} })) }

  describe 'GET /branches?ids=%{public_build.id} needs to be filtered (returns list of builds)' do
    it { expect(body[:branches].size).to eq 1 }
  end

  describe 'GET /branches?ids=%{private_build.id} needs to be filtered (returns list of builds)' do
    it { expect(body[:branches].size).to eq 0 }
  end

  describe 'GET /branches?repository_id=%{repo.id} needs to be filtered (returns list of builds)' do
    it { expect(body[:branches].size).to eq 1 } # TODO should be 1
  end

  describe 'GET /repos/%{repo.id}/branches needs to be filtered (returns list of builds)' do
    it { expect(body[:branches].size).to eq 1 } # TODO should be 1
  end

  describe 'GET /repos/%{repo.slug}/branches needs to be filtered (returns list of builds)' do
    it { expect(body[:branches].size).to eq 1 } # TODO should be 1
  end

  describe 'GET /repos/%{repo.id}/branches/master needs to check visibility' do
    before { Build.where(private: false).delete_all }
    it { expect(status).to eq 404 }
  end

  describe 'GET /builds needs to be filtered' do
    it { expect(body[:builds].size).to eq 1 }
  end

  describe 'GET /builds?repository_id=%{repo.id}&branches=master' do
    before { Build.where(private: false).delete_all }
    it { expect(body[:builds].size).to eq 0 }
  end

  describe 'GET /builds?repository_id=%{repo.id} needs to be filtered' do
    it { expect(body[:builds].size).to eq 1 }
  end

  describe 'GET /builds?repository_id=%{repo.id}&branches=%{private_build.branch} needs to be filtered' do
    it { expect(body[:builds].size).to eq 1 } # TODO should be 1
  end

  describe 'GET /repos/%{repo.id}/builds needs to be filtered' do
    xit { expect(body[:builds].size).to eq 1 } # does not seem to exist?
  end

  describe 'GET /repos/%{repo.slug}/builds needs to be filtered' do
    it { expect(body[:builds].size).to eq 1 }
  end

  describe 'GET /repos/%{repo.slug}/builds?branches=master needs to be filtered (returns list of builds)' do
    it { expect(body[:builds].size).to eq 1 } # it seems params[:branches] is now unused? the local var `name` is not used on that endpoint any more
  end

  describe 'GET /builds/%{public_build.id} needs to check visibility' do
    it { expect(status).to eq 200 }
  end

  describe 'GET /builds/%{private_build.id} needs to check visibility' do
    it { expect(status).to eq 404 }
  end

  describe 'GET /repos/%{repo.slug}/builds/%{public_build.id} needs to check visibility' do
    it { expect(status).to eq 200 }
  end

  describe 'GET /repos/%{repo.id}/builds/%{private_build.id} needs to check visibility' do
    it { expect(status).to eq 404 }
  end

  describe 'GET /jobs/%{public_job.id} needs to check visibility' do
    it { expect(status).to eq 200 }
  end

  describe 'GET /jobs/%{private_job.id} needs to check visibility' do
    it { expect(status).to eq 404 }
  end

  describe 'GET /logs/1 needs to check visibility' do
    it { expect(status).to eq 200 }
  end

  describe 'GET /logs/2 needs to check visibility' do
    it { expect(status).to eq 404 }
  end

  describe 'GET /jobs/%{public_job.id}/log needs to check visibility' do
    it { expect(status).to eq 200 }
  end

  describe 'GET /jobs/%{private_job.id}/log needs to check visibility' do
    it { expect(status).to eq 404 }
  end

  describe 'GET /requests/%{public_request.id} needs to check visibility' do
    it { expect(status).to eq 200 }
  end

  describe 'GET /requests/%{private_request.id} needs to check visibility' do
    it { expect(status).to eq 404 }
  end

  describe 'GET /requests?repository_id=%{repo.id} needs to be filtered' do
    it { expect(body[:requests].size).to eq 1 }
  end

  def method
    example_group_description.split(' ').first.downcase
  end

  def path
    interpolate(self, example_group_description.split(' ')[1])
  end

  def interpolate(obj, str)
    str % Hash.new { |_, key| key.to_s.split('.').inject(obj) { |o, key| o.send(key) } }
  end

  def example_group_description
    RSpec.current_example.example_group.description
  end
end
