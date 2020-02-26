shared_context 'vcs' do
  let!(:url) { Travis::Config.load.vcs.endpoint }
  let!(:token) { Travis::Config.load.vcs.token  }
end