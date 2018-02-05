describe Travis::Services::FindRequest do
  let(:repo)    { Factory(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let!(:request)  { Factory(:request, :repository => repo) }
  let(:params)  { { :id => request.id } }
  let(:service) { described_class.new(stub('user'), params) }

  describe 'run' do
    it 'finds a request by the given id' do
      service.run.should == request
    end

    it 'does not raise if the request could not be found' do
      @params = { :id => request.id + 1 }
      lambda { service.run }.should_not raise_error
    end
  end

  describe 'updated_at' do
    it 'returns request\'s updated_at attribute' do
      service.updated_at.to_s.should == request.updated_at.to_s
    end
  end

  context do
    let(:user) { Factory.create(:user, login: :rkh) }
    let(:org)  { Factory.create(:org, login: :travis) }
    let(:private_repo) { Factory.create(:repository, owner: org, private: true) }
    let(:public_repo)  { Factory.create(:repository, owner: org, private: false) }
    let(:private_request) { Factory.create(:request, repository: private_repo, private: true) }
    let(:public_request)  { Factory.create(:request, repository: public_repo, private: false) }

    before { Travis.config.host = 'example.com' }

    describe 'in public mode' do
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private request' do
          Factory.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_request.id)
          service.run.should == private_request
        end

        it 'finds a public request' do
          Factory.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_request.id)
          service.run.should == public_request
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private request' do
          service = described_class.new(user, id: private_request.id)
          service.run.should be_nil
        end

        it 'finds a public request' do
          service = described_class.new(user, id: public_request.id)
          service.run.should == public_request
        end
      end
    end

    describe 'in private mode' do
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private request' do
          Factory.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_request.id)
          service.run.should == private_request
        end

        it 'finds a public request' do
          Factory.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_request.id)
          service.run.should == public_request
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private request' do
          service = described_class.new(user, id: private_request.id)
          service.run.should be_nil
        end

        it 'does not find a public request' do
          service = described_class.new(user, id: public_request.id)
          service.run.should be_nil
        end
      end
    end
  end
end
