describe 'v2' do
  let(:format)     { :json }
  let(:params)     { { :controller => controller, :action => action, :format => format } }

  describe 'GET to repositories.json?version=2' do
    let(:controller) { 'v2/repositories' }
    let(:action) { :index }

    it 'routes to V2::RepositoriesController#index' do
      expect({ :get => 'repositories.json?version=2' }).to route_to(params)
    end
  end

  describe 'GET to repositories/1.json?version=2' do
    let(:controller) { 'v2/repositories' }
    let(:action) { :show }

    it 'routes to V2::RepositoriesController#show' do
      expect({ :get => 'repositories/1.json?version=2' }).to route_to(params.merge(:id => 1))
    end
  end

  describe 'GET to builds.json?version=2' do
    let(:controller) { 'v2/builds' }
    let(:action) { :index }

    it 'routes to V2::BuildsController#index' do
      expect({ :get => 'builds.json?version=2' }).to route_to(params)
    end
  end

  describe 'GET to builds/1.json?version=2' do
    let(:controller) { 'v2/builds' }
    let(:action) { :show }

    it 'routes to V2::BuildsController#show' do
      expect({ :get => 'builds/1.json?version=2' }).to route_to(params.merge(:id => 1))
    end
  end

  describe 'GET to branches.json?version=2' do
    let(:controller) { 'v2/branches' }
    let(:action) { :index }

    it 'routes to V2::BranchesController#index' do
      expect({ :get => 'branches.json?version=2' }).to route_to(params)
    end
  end

  describe 'GET to jobs.json?version=2' do
    let(:controller) { 'v2/jobs' }
    let(:action) { :index }

    it 'routes to V2::JobsController#index' do
      expect({ :get => 'jobs.json?version=2' }).to route_to(params)
    end
  end

  describe 'GET to jobs/1.json?version=2' do
    let(:controller) { 'v2/jobs' }
    let(:action) { :show }

    it 'routes to V2::JobsController#show' do
      expect({ :get => 'jobs/1.json?version=2' }).to route_to(params.merge(:id => 1))
    end
  end

  describe 'GET to artifacts/1.json?version=2' do
    let(:controller) { 'v2/artifacts' }
    let(:action) { :show }

    it 'routes to V2::ArtifactsController#index' do
      expect({ :get => 'artifacts/1.json?version=2' }).to route_to(params.merge(:id => 1))
    end
  end

  describe 'GET to workers.json?version=2' do
    let(:controller) { 'v2/workers' }
    let(:action) { :index }

    it 'routes to V2::WorkersController#index' do
      expect({ :get => 'workers.json?version=2' }).to route_to(params)
    end
  end

  describe 'GET to service_hooks.json?version=2' do
    let(:controller) { 'v2/service_hooks' }
    let(:action) { :index }

    it 'routes to V2::ServiceHooksController#index' do
      expect({ :get => 'service_hooks.json?version=2' }).to route_to(params)
    end
  end

  describe 'PUT to service_hooks.json?version=2' do
    let(:controller) { 'v2/service_hooks' }
    let(:action) { :update }

    it 'routes to V2::ServiceHooksController#update' do
      hook_params = params.merge(:id => 'svenfuchs:minimal')
      hook_params.delete(:format)

      expect({ :put => 'service_hooks/svenfuchs:minimal?version=2' }).to route_to(hook_params)
    end
  end

  describe 'GET to :owner_name/:name.json?version=2' do
    let(:controller) { 'v2/repositories' }
    let(:action) { :show }

    it 'routes to V2::RepositoriesController#show' do
      expect({ :get => 'owner/name.json?version=2' }).to route_to(params.merge(:owner_name => 'owner', :name => 'name'))
    end

    it 'routes to V2::RepositoriesController#show when owner contains dots' do
      expect({ :get => 'some.owner/name.json?version=2' }).to route_to(params.merge(:owner_name => 'some.owner', :name => 'name'))
    end

    it 'routes to V2::RepositoriesController#show when repository name contains dots' do
      expect({ :get => 'owner/some.name.json?version=2' }).to route_to(params.merge(:owner_name => 'owner', :name => 'some.name'))
    end

    it 'routes to V2::RepositoriesController#show when owner name and repository name contains dots' do
      expect({ :get => 'some.owner/some.name.json?version=2' }).to route_to(params.merge(:owner_name => 'some.owner', :name => 'some.name'))
    end
  end

  describe 'GET to :owner_name/:name.png?version=2' do
    let(:controller) { 'v2/repositories' }
    let(:action) { :show }
    let(:format) { :png }

    it 'routes to V2::RepositoriesController#show' do
      expect({ :get => 'owner/name.png?version=2' }).to route_to(params.merge(:owner_name => 'owner', :name => 'name'))
    end

    it 'routes to V2::RepositoriesController#show when owner contains dots' do
      expect({ :get => 'some.owner/name.png?version=2' }).to route_to(params.merge(:owner_name => 'some.owner', :name => 'name'))
    end

    it 'routes to V2::RepositoriesController#show when repository name contains dots' do
      expect({ :get => 'owner/some.name.png?version=2' }).to route_to(params.merge(:owner_name => 'owner', :name => 'some.name'))
    end

    it 'routes to V2::RepositoriesController#show when owner name and repository name contains dots' do
      expect({ :get => 'some.owner/some.name.png?version=2' }).to route_to(params.merge(:owner_name => 'some.owner', :name => 'some.name'))
    end
  end

  describe 'GET to :owner_name/:name/cc.xml?version=2' do
    let(:controller) { 'v2/repositories' }
    let(:action) { :show }
    let(:format) { :xml }

    it 'routes to V2::RepositoriesController#show in XML format with the cctray schema' do
      expect({ :get => 'owner/name/cc.xml?version=2' }).to route_to(params.merge(:owner_name => 'owner', :name => 'name', :schema => 'cctray'))
    end

    it 'routes to V2::RepositoriesController#show in XML format with the cctray schema when owner and repository name contains dots' do
      expect({ :get => 'some.owner/some.name/cc.xml?version=2' }).to route_to(params.merge(:owner_name => 'some.owner', :name => 'some.name', :schema => 'cctray'))
    end
  end

  describe 'GET to :owner_name/:name/builds.json?version=2' do
    let(:controller) { 'v2/builds' }
    let(:action) { :index }

    it 'routes to V2::BuildsController#index' do
      expect({ :get => 'owner/name/builds.json?version=2' }).to route_to(params.merge(:owner_name => 'owner', :name => 'name'))
    end
  end

  describe 'GET to :owner_name/:name/builds/:id.json?version=2' do
    let(:controller) { 'v2/builds' }
    let(:action) { :show }

    it 'routes to V2::BuildsController#show' do
      expect({ :get => 'owner/name/builds/1.json?version=2' }).to route_to(params.merge(:owner_name => 'owner', :name => 'name', :id => 1))
    end
  end
end
