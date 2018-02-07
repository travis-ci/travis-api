describe Travis::Services::FindBuild do
  let(:repo)    { Factory(:repository, owner_name: 'travis-ci', name: 'travis-core') }
  let!(:build)  { Factory(:build, repository: repo, state: :finished, number: 1, config: {'sudo' => false}) }
  let(:params)  { { id: build.id } }
  let(:service) { described_class.new(stub('user'), params) }

  describe 'run' do
    it 'finds a build by the given id' do
      service.run.should == build
    end

    it 'does not raise if the build could not be found' do
      @params = { :id => build.id + 1 }
      lambda { service.run }.should_not raise_error
    end

    it 'includes config by default' do
      service.run.config.should include(:sudo)
    end

    it 'excludes config when requested' do
      params[:exclude_config] = '1'
      service.run.config.should_not include(:sudo)
    end
  end

  describe 'updated_at' do
    it 'returns builds updated_at attribute' do
      service.updated_at.to_s.should == build.reload.updated_at.to_s
    end
  end

  describe 'with newer associated record' do
    it 'returns updated_at of newest result' do
      # we're using triggers to automatically set updated_at
      # so if we want to force a give updated at we need to disable the trigger
      ActiveRecord::Base.connection.execute("ALTER TABLE builds DISABLE TRIGGER set_updated_at_on_builds;")
      build.update_attribute(:updated_at, 5.minutes.ago)
      ActiveRecord::Base.connection.execute("ALTER TABLE builds ENABLE TRIGGER set_updated_at_on_builds;")
      build.reload.updated_at.should < build.matrix.first.updated_at
      service.updated_at.to_s.should == build.matrix.first.updated_at.to_s
    end
  end

  describe 'without updated_at in one of the resources' do
    it 'returns updated_at of newest result' do
      Build.any_instance.stubs(updated_at: nil)
      expect {
        service.updated_at
      }.to_not raise_error
    end
  end

  # TODO builds can be requeued, so finished builds are no more final
  #
  # describe 'final?' do
  #   it 'returns true if the build is finished' do
  #     build.update_attributes!(:state => :errored)
  #     service.final?.should be_truthy
  #   end

  #   it 'returns false if the build is not finished' do
  #     build.update_attributes!(:state => :started)
  #     service.final?.should be false
  #   end
  # end
end
