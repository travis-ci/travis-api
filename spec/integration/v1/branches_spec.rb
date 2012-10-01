require 'spec_helper'

describe 'Branches' do
  before { Scenario.default }

  let(:repo) { Repository.first }

  it 'GET /branches?repository_id=:repository_id' do
    response = get "/branches?repository_id=#{repo.id}"
    response.should deliver_json_for('branches/all', 'v1', { repository_id: repo.id }, type: 'branches')
  end
end
