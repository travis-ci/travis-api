describe Travis::API::V3::Services::Repositories::ForCurrentUser, set_app: true do
  before { Repository.destroy_all }
  let(:user)      { FactoryGirl.create(:user) }
  let(:web_repo)  { FactoryGirl.create(:repository, owner_name: 'travis-ci', name: 'travis-web') }
  let(:api_repo)  { FactoryGirl.create(:repository, owner_name: 'travis-ci', name: 'travis-api') }
  let(:long_name) { FactoryGirl.create(:repository, owner_name: 'this-is', name: 'rather-vague') }

  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1)             }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                    }}
  before        { Travis::API::V3::Models::Permission.create(repository: web_repo, user: user, pull: true, push: true, admin: true) }
  before        { Travis::API::V3::Models::Permission.create(repository: api_repo, user: user, pull: true, push: true, admin: true) }
  before        { Travis::API::V3::Models::Permission.create(repository: long_name, user: user, pull: true, push: true, admin: true) }

  it "filters by query" do
    get("/v3/repos?slug_filter=trvs&sort_by=slug_filter:desc,id:desc", {}, headers)

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
