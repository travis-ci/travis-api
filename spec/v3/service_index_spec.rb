describe Travis::API::V3::ServiceIndex, set_app: true do
  let(:headers)   {{                        }}
  let(:path)      { '/'                      }
  let(:json)      { JSON.load(response.body) }
  let(:response)  { get(path, {}, headers)   }
  let(:resources) { json.fetch('resources')  }

  describe "custom json entry point" do
    shared_examples 'service index' do
      describe "requests resource" do
        let(:resource) { resources.fetch("requests") }
        specify { expect(resources)         .to include("requests") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("find") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}repo/{repository.id}/requests{?include,limit,offset}") }
        end

        describe "create action" do
          let(:action) { resource.fetch("actions").fetch("create") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"POST", "uri_template"=>"#{path}repo/{repository.id}/requests") }
        end
      end

      describe "branch resource" do
        let(:resource) { resources.fetch("branch") }
        specify { expect(resources)         .to include("branch") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("find") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}repo/{repository.id}/branch/{branch.name}{?include}") }
        end
      end

      describe "repository resource" do
        let(:resource) { resources.fetch("repository") }
        specify { expect(resources)         .to include("repository") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("find") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}repo/{repository.id}{?include}") }
        end

        describe "activate action" do
          let(:action) { resource.fetch("actions").fetch("activate") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"POST", "uri_template"=>"#{path}repo/{repository.id}/activate") }
        end

        describe "deactivate action" do
          let(:action) { resource.fetch("actions").fetch("deactivate") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"POST", "uri_template"=>"#{path}repo/{repository.id}/deactivate") }
        end
      end

      describe "repositories resource" do
        let(:resource) { resources.fetch("repositories") }
        specify { expect(resources)         .to include("repositories") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "for_current_user action" do
          let(:action) { resource.fetch("actions").fetch("for_current_user") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}repos{?active,include,limit,offset,private,repository.active,repository.private,repository.starred,sort_by,starred}") }
        end
      end

      describe "build resource" do
        let(:resource) { resources.fetch("build") }
        specify { expect(resources)         .to include("build") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("find") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}build/{build.id}{?include}") }
        end
      end

      describe "organization resource" do
        let(:resource) { resources.fetch("organization") }
        specify { expect(resources)         .to include("organization") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("find") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}org/{organization.id}{?include}") }
        end
      end

      describe "owner resource" do
        let(:resource) { resources.fetch("owner") }
        specify { expect(resources)         .to include("owner") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("find") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}owner/{owner.login}{?include}") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}owner/{user.login}{?include}") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}owner/{organization.login}{?include}") }
        end
      end

      describe "organizations resource" do
        let(:resource) { resources.fetch("organizations") }
        specify { expect(resources)         .to include("organizations") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "for_current_user action" do
          let(:action) { resource.fetch("actions").fetch("for_current_user") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}orgs{?include,limit,offset,sort_by}") }
        end
      end

      describe "user resource" do
        let(:resource) { resources.fetch("user") }
        specify { expect(resources)         .to include("user") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "current action" do
          let(:action) { resource.fetch("actions").fetch("current") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}user{?include}") }
        end

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("find") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}user/{user.id}{?include}") }
        end
      end
    end

    describe 'with /v3 prefix' do
      let(:path) { '/v3/' }
      it_behaves_like 'service index'
    end

    describe 'with Accept header' do
      let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.3+json' } }
      it_behaves_like 'service index'
    end

    describe 'with Travis-API-Version header' do
      let(:headers) { { 'HTTP_TRAVIS_API_VERSION' => '3' } }
      it_behaves_like 'service index'
    end
  end

  describe "json-home document" do
    describe 'with /v3 prefix' do
      let(:headers) { { 'HTTP_ACCEPT' => 'application/json-home' } }
      let(:path) { '/v3/' }
      specify(:resources) { expect(json['resources']).to include("http://schema.travis-ci.com/rel/repository/find/by_repository.id") }
    end

    describe 'with Travis-API-Version header' do
      let(:headers) { { 'HTTP_ACCEPT' => 'application/json-home', 'HTTP_TRAVIS_API_VERSION' => '3' } }
      specify(:resources) { expect(json['resources']).to include("http://schema.travis-ci.com/rel/repository/find/by_repository.id") }
    end
  end
end
