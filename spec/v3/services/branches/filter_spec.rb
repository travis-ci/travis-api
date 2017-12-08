describe Travis::API::V3::Services::Branches, set_app: true do
  before { Repository.destroy_all }
  let(:user)          { FactoryGirl.create(:user) }
  let!(:repo)         { FactoryGirl.create(:repository, owner_name: 'travis-ci', name: 'travis-web') }

  let!(:jorts_branch) { FactoryGirl.create(:branch, repository: repo, name: 'jorts')}
  let!(:jants_branch) { FactoryGirl.create(:branch, repository: repo, name: 'jants')}
  let!(:other_branch) { FactoryGirl.create(:branch, repository: repo, name: 'other')}
  let!(:ochre_branch) { FactoryGirl.create(:branch, repository: repo, name: 'ochre')}

  let!(:jorts_build)  { FactoryGirl.create(:v3_build, repository: repo, branch_name: "jorts") }
  let!(:jants_build)  { FactoryGirl.create(:v3_build, repository: repo, branch_name: "jants") }
  let!(:other_build)  { FactoryGirl.create(:v3_build, repository: repo, branch_name: "other") }
  let!(:ochre_build)  { FactoryGirl.create(:v3_build, repository: repo, branch_name: "ochre") }

  let(:token)         { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers)       {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  before              { Travis::API::V3::Models::Permission.create(repository: repo, user: user, pull: true, push: true, admin: true) }

  it "filters by query", focus: true do
    get("/v3/repo/#{repo.id}/branches?name_filter=ts&sort_by=name:desc", {}, headers)

    names = parsed_body['branches'].map { |branch_data| branch_data['name'] }

    expect(names).to eql(['jorts', 'jants'])
  end

  # FIXME name_filter vs name_filter:desc have the same result? 🤔
  xit "orders by proximity" do
    get("/v3/repo/#{repo.id}/branches?name_filter=ohr&sort_by=name_filter", {}, headers)

    names = parsed_body['branches'].map { |branch_data| branch_data['name'] }

    expect(names).to eql(["ochre", "other"])
  end

  # it "warns about sorting without slug_filter" do
  #   get("/v3/repos?sort_by=slug_filter:desc,id:desc", {}, headers)
  #
  #   warning = parsed_body['@warnings'][0]
  #   expect(warning['message']).to eql("slug_filter sort was selected, but slug_filter param is not supplied, ignoring")
  # end
end
