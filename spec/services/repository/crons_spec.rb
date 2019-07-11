require 'rails_helper'

RSpec.describe Services::Repository::Crons do
  let!(:repo)    { create(:repository) }
  let!(:crons_service) { Services::Repository::Crons.new(repo) }

  fake_crons = [{'branch' => 'master'}, {'branch' => 'latest'}]

  describe '#call' do
    it 'calls travis api /crons endpoint and returns array of available crons' do
      WebMock.stub_request(:get, "https://api-fake.travis-ci.com/repo/#{repo.slug}/crons").
          to_return(status: 200, body: fake_crons)
      expect(crons_service.call.body).to eq(fake_crons)
    end
  end
end
