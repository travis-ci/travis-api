describe Travis::API::V3::Services::Branches, set_app: true do
  before { Repository.destroy_all }
  let(:user)          { FactoryGirl.create(:user) }
  let!(:repo)         { FactoryGirl.create(:repository, owner_name: 'travis-ci', name: 'travis-web') }

  let!(:jorts_branch) { FactoryGirl.create(:branch, repository: repo, name: 'jorts')}
  let!(:jants_branch) { FactoryGirl.create(:branch, repository: repo, name: 'jants')}
  let!(:other_branch) { FactoryGirl.create(:branch, repository: repo, name: 'other')}

  let!(:jorts_build)  { FactoryGirl.create(:v3_build, repository: repo, branch_name: "jorts") }
  let!(:jants_build)  { FactoryGirl.create(:v3_build, repository: repo, branch_name: "jants") }
  let!(:other_build)  { FactoryGirl.create(:v3_build, repository: repo, branch_name: "other") }

  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  before        { Travis::API::V3::Models::Permission.create(repository: repo, user: user, pull: true, push: true, admin: true) }

  it "filters by query", focus: true do
    # FIXME add name_filter sort?
    get("/v3/repo/#{repo.id}/branches?name_filter=ts&sort_by=name:desc", {}, headers)

    names = parsed_body['branches'].map { |branch_data| branch_data['name'] }

    expect(names).to eql(['jorts', 'jants'])
  end

  # it "orders by words distance" do
  #   get("/v3/repos?repository.slug_filter=trav&sort_by=slug_filter:desc,id:desc", {}, headers)
  #
  #   slugs = parsed_body['repositories'].map { |repo_data| repo_data['slug'] }
  #
  #   expect(slugs).to eql(["travis-ci/travis-api", "travis-ci/travis-web", "this-is/rather-vague"])
  # end
  #
  # it "warns about sorting without slug_filter" do
  #   get("/v3/repos?sort_by=slug_filter:desc,id:desc", {}, headers)
  #
  #   warning = parsed_body['@warnings'][0]
  #   expect(warning['message']).to eql("slug_filter sort was selected, but slug_filter param is not supplied, ignoring")
  # end
end
