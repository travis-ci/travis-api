require 'spec_helper'

require 'travis/api/v3/routes'
require 'travis/api/v3/service'
require 'travis/api/v3/services'

module Travis::API::V3
  module Services
    Foo = Module.new { extend Travis::API::V3::Services }
    Foo::Find = Class.new(Travis::API::V3::Service)
    Foo::DoSomething = Class.new(Travis::API::V3::Service)
    Foo::DoSomethingSecret = Class.new(Travis::API::V3::Service)

    Bar = Module.new { extend Travis::API::V3::Services }
    Bar::Find = Class.new(Travis::API::V3::Service)
  end

  class Services::Foo::Find < Service
    def run!
      head
    end
  end

  module Routes
    resource :foo do
      route '/foo'
      get :find

      hide(post :do_something_secret, '/do_something_secret')
      post :do_something, '/do_something'
    end

    hidden_resource :bar do
      route '/bar'
      get :find
    end
  end
end

describe Travis::API::V3::ServiceIndex, set_app: true do
  let(:headers)   {{                        }}
  let(:path)      { '/'                      }
  let(:json)      { JSON.load(response.body) }
  let(:response)  { get(path, {}, headers)   }
  let(:resources) { json.fetch('resources')  }

  describe 'hiding resources and routes' do
    let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.3+json' } }

    it 'hides a resource from the service index' do
      expect(json['resources']).to have_key('foo')
      expect(json['resources']).to_not have_key('bar')
      expect(json['resources']['foo']['actions']).to have_key('do_something')
      expect(json['resources']['foo']['actions']).to_not have_key('do_something_secret')
    end
  end

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
          specify do
            expect(action).to include(
              "@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/requests",
              "accepted_params" => %w(
                request.merge_mode
                request.config
                request.configs
                request.message
                request.branch
                request.sha
                request.token
              )
            )
          end
        end
      end

      describe "home resource" do
        let(:resource) { resources.fetch("home") }
        specify { expect(resources)         .to include("home")   }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("find") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>path) }
        end
      end

      # describe "home resource" do
      #   let(:resource) { resources.fetch("stage") }
      #   specify { expect(resources)              .to include("stage") }
      #   specify { expect(resource["@type"])      .to be == "resource" }
      #   specify { expect(resource["attributes"]) .to include("name")  }
      # end

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
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}repo/{repository.id}{?include,repository.server_type,server_type}") }
        end

        describe "activate action" do
          let(:action) { resource.fetch("actions").fetch("activate") }
          specify do
            expect(action).to include(
              "@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/activate",
              "accepted_params" => []
            )
          end
        end

        describe "deactivate action" do
          let(:action) { resource.fetch("actions").fetch("deactivate") }
          specify do
            expect(action).to include(
              "@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/deactivate",
              "accepted_params" => []
            )
          end
        end
      end

      describe "repositories resource" do
        let(:resource) { resources.fetch("repositories") }
        specify { expect(resources)         .to include("repositories") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "for_current_user action" do
          let(:action) { resource.fetch("actions").fetch("for_current_user") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}repos{?active,active_on_org,include,limit,managed_by_installation,offset,private,repository.active,repository.active_on_org,repository.managed_by_installation,repository.private,repository.starred,sort_by,starred}") }
        end
      end

      describe "env_vars resource" do
        let(:resource) { resources.fetch("env_vars") }
        specify { expect(resources)         .to include("env_vars") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "for_repository action" do
          let(:action) { resource.fetch("actions").fetch("for_repository") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}repo/{repository.id}/env_vars{?include}") }
        end

        describe "create action" do
          let(:action) { resource.fetch("actions").fetch("create") }
          specify do
            expect(action).to include(
              "@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/env_vars",
              "accepted_params" => ["env_var.name", "env_var.value", "env_var.public", "env_var.branch"]
            )
          end
        end
      end

      describe "env_var resource" do
        let(:resource) { resources.fetch("env_var") }
        specify { expect(resources)         .to include("env_var") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "update action" do
          let(:action) { resource.fetch("actions").fetch("update") }
          specify do
            expect(action).to include(
              "@type"=>"template",
              "request_method"=>"PATCH",
              "uri_template"=>"#{path}repo/{repository.id}/env_var/{env_var.id}",
              "accepted_params" => ["env_var.name", "env_var.value", "env_var.public", "env_var.branch"]
            )
          end
        end

        describe "delete action" do
          let(:action) { resource.fetch("actions").fetch("delete") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"DELETE", "uri_template"=>"#{path}repo/{repository.id}/env_var/{env_var.id}") }
        end
      end

      describe "user_settings resource" do
        let(:resource) { resources.fetch("settings") }
        specify { expect(resources)         .to include("settings") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("for_repository") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}repo/{repository.id}/settings{?include}") }
        end
      end

      describe "user_setting resource" do
        let(:resource) { resources.fetch("setting") }
        specify { expect(resources)         .to include("setting") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("find") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}repo/{repository.id}/setting/{setting.name}{?include}") }
        end

        describe "update action" do
          let(:action) { resource.fetch("actions").fetch("update") }
          specify do
            expect(action).to include(
              "@type"=>"template",
              "request_method"=>"PATCH",
              "uri_template"=>"#{path}repo/{repository.id}/setting/{setting.name}",
              "accepted_params" => ["setting.value"]
            )
          end
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

      describe "key pair resource" do
        let(:resource) { resources.fetch("key_pair") }
        specify { expect(resources)         .to include("key_pair") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("find") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}repo/{repository.id}/key_pair{?include}") }
        end

        describe "create action" do
          let(:action) { resource.fetch("actions").fetch("create") }
          specify do
            expect(action).to include(
              "@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/key_pair",
              "accepted_params" => ["key_pair.description", "key_pair.value"]
            )
          end
        end
      end

      describe "key pair (generated) resource" do
        let(:resource) { resources.fetch("key_pair_generated") }
        specify { expect(resources)         .to include("key_pair_generated") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "find action" do
          let(:action) { resource.fetch("actions").fetch("find") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}repo/{repository.id}/key_pair/generated{?include}") }
        end

        describe "create action" do
          let(:action) { resource.fetch("actions").fetch("create") }
          specify do
            expect(action).to include(
              "@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/key_pair/generated",
              "accepted_params" => []
            )
          end
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
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}owner/{login}{?include}") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}owner/{provider}/{login}{?include}") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}owner/github_id/{github_id}{?include}") }
        end
      end

      describe "organizations resource" do
        let(:resource) { resources.fetch("organizations") }
        specify { expect(resources)         .to include("organizations") }
        specify { expect(resource["@type"]) .to be == "resource"  }

        describe "for_current_user action" do
          let(:action) { resource.fetch("actions").fetch("for_current_user") }
          specify { expect(action).to include("@type"=>"template", "request_method"=>"GET", "uri_template"=>"#{path}orgs{?include,limit,offset,organization.role,role,sort_by}") }
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

      describe "subscriptions resource" do
        it 'is hidden' do
          expect(resources).to_not have_key('subscriptions')
        end
      end

      describe "subscription resource" do
        it 'is hidden' do
          expect(resources).to_not have_key('subscription')
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
