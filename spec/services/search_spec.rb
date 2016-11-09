require 'rails_helper'

RSpec.describe Services::Search do
  let!(:user)          { create(:user, id: 162, login: 'lisbethmarianne', name: 'Katrin', email: 'katrin@example.com') }
  let!(:user2)         { create(:user, id: 12, github_id: 12324) }
  let!(:email)         { create(:email, user: user, email: 'lisbethmarianne@example.com') }
  let!(:organization)  { create(:organization, id: 46, login: 'rubymonstas', name: 'Ruby Monstas', homepage: 'http://rubymonstas.org/') }
  let!(:organization2) { create(:organization, id: 16, github_id: 9267, login: 'travis-ci') }
  let!(:repository)    { create(:repository, owner: organization, id: 416, owner_name: organization.login, name: 'diversitytickets') }
  let!(:repository2)   { create(:repository, id: 361, owner: organization, owner_name: organization.login, name: 'travis-ci') }
  let!(:request)       { create(:request, id: 4567) }
  let!(:commit)        { create(:commit, repository: repository) }
  let!(:build)         { create(:build, id: 6397, owner: organization, repository: repository, commit: commit, number: 567) }
  let!(:job)           { create(:job, id: 35465, owner: organization, repository: repository,  commit: commit, build: build, number: 567.1) }

  let(:search) { Services::Search.new(query).call }

  context 'explicit search (search by type and id)' do
    describe 'search for "repo 416" finds repository with id=416' do
      let(:query) { 'repo 416' }
      it { expect(search).to eq([repository]) }
    end

    describe 'search for "repository 416" finds repository with id=416' do
      let(:query) { 'repository 416' }
      it { expect(search).to eq([repository]) }
    end

    describe 'search for "request 4567" finds request with id=4567' do
      let(:query) { 'request 4567' }
      it { expect(search).to eq([request]) }
    end

    describe 'search for "build 6397" finds build with id=6397' do
      let(:query) { 'build 6397' }
      it { expect(search).to eq([build]) }
    end

    describe 'search for "job 35465" finds job with id 35465' do
      let(:query) { 'job 35465' }
      it { expect(search).to eq([job]) }
    end

    describe 'search for "user 162" finds user with id 162' do
      let(:query) { 'user 162' }
      it { expect(search).to eq([user]) }
    end

    describe 'search for "user 12324" finds user with github_id 12324' do
      let(:query) { 'user 12324' }
      it { expect(search).to eq([user2]) }
    end

    describe 'search for "organization 46" finds organization with id 46' do
      let(:query) { 'organization 46' }
      it { expect(search).to eq([organization]) }
    end

    describe 'search for "organization 9267" finds user with github_id 9267' do
      let(:query) { 'organization 9267' }
      it { expect(search).to eq([organization2]) }
    end
  end

  context 'search for login' do
    describe 'search for "lisbethmarianne" finds user with login "lisbethmarianne"' do
      let(:query) { 'lisbethmarianne' }
      it { expect(search).to eq([user]) }
    end

    describe 'search for "rubymonstas" finds organization with login "rubymonstas"' do
      let(:query) { 'rubymonstas' }
      it { expect(search).to eq([organization]) }
    end

    describe 'search for "Rubymonstas" finds organization with login="rubymonstas"' do
      let(:query) { 'Rubymonstas' }
      it { expect(search).to eq([organization]) }
    end

    describe 'search for "travis-ci" finds organization with login "travis-ci" as well as repo with name "travis-ci"' do
      let(:query) { 'travis-ci' }
      it { expect(search).to include organization2 }
      it { expect(search).to include repository2 }
    end
  end

  context 'search for name' do
    describe 'search for "Katrin" finds user with name "Katrin"' do
      let(:query) { 'Katrin' }
      it { expect(search).to eq([user]) }
    end

    describe 'search for "Ruby Monstas" finds organization with name "Ruby Monstas"' do
      let(:query) { 'Ruby Monstas' }
      it { expect(search).to eq([organization]) }
    end

    describe 'search for "ruby monstas" finds organization with name "Ruby Monstas"' do
      let(:query) { 'ruby monstas' }
      it { expect(search).to eq([organization]) }
    end

    describe 'search for "diversitytickets" finds repository with name="diversitytickets"' do
      let(:query) { 'diversitytickets' }
      it { expect(search).to eq([repository]) }
    end
  end

  context 'search for email' do
    describe 'search for "katrin@example.com" finds user with email "katrin@example.com"' do
      let(:query) { 'katrin@example.com' }
      it { expect(search).to eq([user]) }
    end

    describe 'search for "lisbethmarianne@example.com" finds user with secondary email "lisbethmarianne@example.com"' do
      let(:query) { 'lisbethmarianne@example.com' }
      it { expect(search).to eq([user]) }
    end
  end

  context 'search for homepage' do
    describe 'search for "http://rubymonstas.org/" finds organization with homepage "http://rubymonstas.org/"' do
      let(:query) { 'http://rubymonstas.org/' }
      it { expect(search).to eq([organization]) }
    end
  end

  context 'search for repository slug' do
    describe 'search for "rubymonstas/diversitytickets" finds repository with slug "rubymonstas/diversitytickets"' do
      let(:query) { 'rubymonstas/diversitytickets' }
      it { expect(search).to eq([repository]) }
    end
  end

  context 'search for build slug' do
    describe 'search for "rubymonstas/diversitytickets#567" finds build with slug="rubymonstas/diversitytickets#567"' do
      let(:query) { 'rubymonstas/diversitytickets#567' }
      it { expect(search).to eq([build]) }
    end
  end

  context 'search for job slug' do
    describe 'search for "rubymonstas/diversitytickets#567.1" finds job with slug "rubymonstas/diversitytickets#567.1"' do
      let(:query) { 'rubymonstas/diversitytickets#567.1' }
      it { expect(search).to eq([job]) }
    end
  end

  context 'search with github url' do
    describe 'search for "https://github.com/lisbethmarianne" finds user with login "lisbethmarianne"' do
      let(:query) { 'https://github.com/lisbethmarianne' }
      it { expect(search).to eq([user]) }
    end

    describe 'search for "https://github.com/LisbethMarianne" finds user with login "lisbethmarianne"' do
      let(:query) { 'https://github.com/LisbethMarianne' }
      it { expect(search).to eq([user]) }
    end

    describe 'search for "https://github.com/rubymonstas" finds organization with login "rubymonstas"' do
      let(:query) { 'https://github.com/rubymonstas' }
      it { expect(search).to eq([organization]) }
    end

    describe 'search for "https://github.com/rubymonstas/diversitytickets" finds repository with slug "rubymonstas/diversitytickets"' do
      let(:query) { 'https://github.com/rubymonstas/diversitytickets' }
      it { expect(search).to eq([repository]) }
    end
  end

  context 'search with travis-ci url' do
    describe 'search for "https://travis-ci.com/profile/lisbethmarianne" finds user with login="lisbethmarianne"' do
      let(:query) { 'https://travis-ci.com/profile/lisbethmarianne' }
      it { expect(search).to eq([user]) }
    end

    describe 'search for "https://travis-ci.com/profile/LisbethMarianne" finds user with login="lisbethmarianne"' do
      let(:query) { 'https://travis-ci.com/profile/LisbethMarianne' }
      it { expect(search).to eq([user]) }
    end

    describe 'search for "https://travis-ci.com/profile/rubymonstas" finds organization with login "rubymonstas"'do
      let(:query) { 'https://travis-ci.com/profile/rubymonstas' }
      it { expect(search).to eq([organization]) }
    end

    describe 'search for "https://travis-ci.com/rubymonstas/diversitytickets" finds repository with slug "rubymonstas/diversitytickets"' do
      let(:query) { 'https://travis-ci.com/rubymonstas/diversitytickets' }
      it { expect(search).to eq([repository]) }
    end

    describe 'search for "https://travis-ci.com/rubymonstas/diversitytickets/builds/6397" finds build with id 6397' do
      let(:query) { 'https://travis-ci.com/rubymonstas/diversitytickets/builds/6397' }
      it { expect(search).to eq([build]) }
    end

    describe 'search for "https://travis-ci.com/rubymonstas/diversitytickets/jobs/35465" finds job with id 35465' do
      let(:query) { 'https://travis-ci.com/rubymonstas/diversitytickets/jobs/35465' }
      it { expect(search).to eq([job]) }
    end
  end
end
