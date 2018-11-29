describe Travis::API::V3::Services::Repositories::ForCurrentUser, set_app: true do
  let(:user)    { FactoryGirl.create(:user) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

  before { ActiveRecord::Base.connection.execute("truncate repositories cascade") }

  describe 'name_filter' do
    let(:web_repo)  { FactoryGirl.create(:repository, name: 'travis-web') }
    let(:api_repo)  { FactoryGirl.create(:repository, name: 'travis-api') }
    let(:long_name) { FactoryGirl.create(:repository, name: 'this-rather-vague') }

    before { Travis::API::V3::Models::Permission.create(repository: web_repo, user: user, pull: true, push: true, admin: true) }
    before { Travis::API::V3::Models::Permission.create(repository: api_repo, user: user, pull: true, push: true, admin: true) }
    before { Travis::API::V3::Models::Permission.create(repository: long_name, user: user, pull: true, push: true, admin: true) }

    it "filters by query" do
      get("/v3/repos?name_filter=Trvs&sort_by=id:desc", {}, headers)

      names = parsed_body['repositories'].map { |repo_data| repo_data['name'] }

      expect(names).to eql(['travis-api', 'travis-web'])
    end

    it "orders by words distance" do
      get("/v3/repos?name_filter=trav&sort_by=name_filter:desc,id:desc", {}, headers)

      names = parsed_body['repositories'].map { |repo_data| repo_data['name'] }

      expect(names).to eql(["travis-api", "travis-web", "this-rather-vague"])
    end

    it "warns about sorting without name_filter" do
      get("/v3/repos?sort_by=name_filter:desc,id:desc", {}, headers)

      warning = parsed_body['@warnings'][0]
      expect(warning['message']).to eql("name_filter sort was selected, but name_filter param is not supplied, ignoring")
    end
  end

  describe 'slug_filter' do
    let(:web_repo)  { FactoryGirl.create(:repository, owner_name: 'travis-ci', name: 'travis-web') }
    let(:api_repo)  { FactoryGirl.create(:repository, owner_name: 'travis-ci', name: 'travis-api') }
    let(:long_name) { FactoryGirl.create(:repository, owner_name: 'this-is', name: 'rather-vague') }

    before { Travis::API::V3::Models::Permission.create(repository: web_repo, user: user, pull: true, push: true, admin: true) }
    before { Travis::API::V3::Models::Permission.create(repository: api_repo, user: user, pull: true, push: true, admin: true) }
    before { Travis::API::V3::Models::Permission.create(repository: long_name, user: user, pull: true, push: true, admin: true) }

    it "filters by query" do
      get("/v3/repos?slug_filter=Trvs&sort_by=slug_filter:desc,id:desc", {}, headers)

      slugs = parsed_body['repositories'].map { |repo_data| repo_data['slug'] }

      expect(slugs).to eql(['travis-ci/travis-api', 'travis-ci/travis-web'])
    end

    it "orders by words distance" do
      get("/v3/repos?repository.slug_filter=trav&sort_by=slug_filter:desc,id:desc", {}, headers)

      slugs = parsed_body['repositories'].map { |repo_data| repo_data['slug'] }

      expect(slugs).to eql(["travis-ci/travis-api", "travis-ci/travis-web", "this-is/rather-vague"])
    end

    it "warns about sorting without slug_filter" do
      get("/v3/repos?sort_by=slug_filter:desc,id:desc", {}, headers)

      warning = parsed_body['@warnings'][0]
      expect(warning['message']).to eql("slug_filter sort was selected, but slug_filter param is not supplied, ignoring")
    end
  end

  describe 'active_on_org' do
    before do
      repos = [
        FactoryGirl.create(:repository, name: 'on-org', active_on_org: true),
        FactoryGirl.create(:repository, name: 'off-org', active_on_org: false),
        FactoryGirl.create(:repository, name: 'off-org-2', active_on_org: nil)
      ]
      repos.each do |repo|
        Travis::API::V3::Models::Permission.create(repository: repo, user: user, pull: true, push: true, admin: true)
      end
    end

    describe "filter: active_on_org=true" do
      before  { get("/v3/repos?repository.active_on_org=true", {}, headers) }
      example { expect(last_response).to be_ok }
      example { expect(JSON.load(body)['@href']).to eq '/v3/repos?repository.active_on_org=true' }
      example { expect(JSON.load(body)['repositories'].size).to eq 1 }
    end

    describe "filter: active_on_org=false" do
      before  { get("/v3/repos?repository.active_on_org=false", {}, headers) }
      example { expect(last_response).to be_ok }
      example { expect(JSON.load(body)['@href']).to eq '/v3/repos?repository.active_on_org=false' }
      example { expect(JSON.load(body)['repositories'].size).to eq 2 }
    end
  end
end
