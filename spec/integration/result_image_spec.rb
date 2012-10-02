require 'spec_helper'

describe 'Result images' do
  let!(:repo) { Factory(:repository, owner_name: 'svenfuchs', name: 'minimal') }

  describe 'GET /svenfuchs/minimal.png' do
    it '"unknown" when the repository does not exist' do
      get('/svenfuchs/does-not-exist.png').should deliver_result_image_for('unknown')
    end

    it '"unknown" when it only has one build that is not finished' do
      repo.update_attributes!(last_build_result: nil)
      get('/svenfuchs/minimal.png').should deliver_result_image_for('unknown')
    end

    it '"failing" when the last build has failed' do
      repo.update_attributes!(last_build_result: 1)
      get('/svenfuchs/minimal.png').should deliver_result_image_for('failing')
    end

    it '"passing" when the last build has passed' do
      repo.update_attributes!(last_build_result: 0)
      get('/svenfuchs/minimal.png').should deliver_result_image_for('passing')
    end

    it '"passing" when there is a running build but the previous one has passed' do
      Factory(:build, repository: repo, state: :finished, result: nil, previous_result: 0)
      repo.update_attributes!(last_build_result: nil)
      get('/svenfuchs/minimal.png').should deliver_result_image_for('passing')
    end
  end

  describe 'GET /svenfuchs/minimal.png' do
    let(:commit) { Factory(:commit, branch: 'dev') }

    it '"unknown" when the repository does not exist' do
      get('/svenfuchs/does-not-exist.png?branch=dev').should deliver_result_image_for('unknown')
    end

    it '"unknown" when it only has a build that is not finished' do
      Factory(:build, repository: repo, state: :started, result: nil, commit: commit)
      get('/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('unknown')
    end

    it '"failing" when the last build has failed' do
      Factory(:build, repository: repo, state: :finished, result: 1, commit: commit)
      get('/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('failing')
    end

    it '"passing" when the last build has passed' do
      Factory(:build, repository: repo, state: :finished, result: 0, commit: commit)
      get('/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('passing')
    end

    it '"passing" when there is a running build but the previous one has passed' do
      Factory(:build, repository: repo, state: :finished, result: 0, commit: commit)
      Factory(:build, repository: repo, state: :started, result: nil, commit: commit)
      repo.update_attributes!(last_build_result: nil)
      get('/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('passing')
    end
  end
end
