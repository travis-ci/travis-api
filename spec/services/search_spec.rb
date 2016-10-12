require 'rails_helper'

RSpec.describe Services::Search do
  let!(:user)          { create(:user, id: 162, login: 'lisbethmarianne', name: 'Katrin', email: 'katrin@example.com') }
  let!(:user2)         { create(:user, id: 12, github_id: 12324) }
  let!(:email)         { create(:email, user_id: 162, email: 'lisbethmarianne@example.com') }
  let!(:organization)  { create(:organization, id: 46, login: 'rubymonstas', name: 'Ruby Monstas', homepage: 'http://rubymonstas.org/') }
  let!(:organization2) { create(:organization, id: 16, github_id: 9267, login: 'travis-ci') }
  let!(:repository)    { create(:repository, id: 416, owner_name: organization.login, name: 'diversitytickets') }
  let!(:repository2)   { create(:repository, id: 361, owner_name: organization.login, name: 'travis-ci') }
  let!(:request)       { create(:request, id: 4567) }
  let!(:build)         { create(:build, id: 6397, repository: repository, number: 567) }
  let!(:job)           { create(:job, id: 35465, repository: repository, number: 567.1) }

  context "explicit search (search by type and id)" do
    it "finds repository with id=416 for 'repo 416'" do
      query = 'repo 416'
      results = Services::Search.new(query).call

      expect(results).to eq([repository])
    end

    it "finds repository with id=416 for 'repository 416'" do
      query = 'repository 416'
      results = Services::Search.new(query).call

      expect(results).to eq([repository])
    end

    it "finds request with id=4567 for 'request 4567'" do
      query = 'request 4567'
      results = Services::Search.new(query).call

      expect(results).to eq([request])
    end

    it "finds build with id=6397 for 'build 6397'" do
      query = 'build 6397'
      results = Services::Search.new(query).call

      expect(results).to eq([build])
    end

    it "finds job with id=35465 for 'job 35465'" do
      query = 'job 35465'
      results = Services::Search.new(query).call

      expect(results).to eq([job])
    end

    it "finds user with id=162 for 'user 162'" do
      query = 'user 162'
      results = Services::Search.new(query).call

      expect(results).to eq([user])
    end

    it "finds user with github_id=12324 for 'user 12324'" do
      query = 'user 12324'
      results = Services::Search.new(query).call

      expect(results).to eq([user2])
    end

    it "finds organization with id=46 for 'organization 46'" do
      query = 'organization 46'
      results = Services::Search.new(query).call

      expect(results).to eq([organization])
    end

    it "finds user with github_id=9267 for 'organization 9267'" do
      query = 'organization 9267'
      results = Services::Search.new(query).call

      expect(results).to eq([organization2])
    end
  end

  context "search for login" do
    it "finds user with login='lisbethmarianne' for 'lisbethmarianne'" do
      query = 'lisbethmarianne'
      results = Services::Search.new(query).call

      expect(results).to eq([user])
    end

    it "finds organization with login='rubymonstas' for 'rubymonstas'" do
      query = 'rubymonstas'
      results = Services::Search.new(query).call

      expect(results).to eq([organization])
    end

    it "finds organization with login='travis-ci' as well as repo with name='travis-ci' for 'travis-ci'" do
      query = 'travis-ci'
      results = Services::Search.new(query).call

      expect(results).to include organization2
      expect(results).to include repository2
    end
  end

  context "search for name" do
    it "finds user with name='Katrin' for 'Katrin'" do
      query = 'Katrin'
      results = Services::Search.new(query).call

      expect(results).to eq([user])
    end

    it "finds organization with name='Ruby Monstas' for 'Ruby Monstas'" do
      query = 'Ruby Monstas'
      results = Services::Search.new(query).call

      expect(results).to eq([organization])
    end

    it "finds repository with name='diversitytickets' for 'diversitytickets'" do
      query = 'diversitytickets'
      results = Services::Search.new(query).call

      expect(results).to eq([repository])
    end
  end

  context "search for email" do
    it "finds user with email='katrin@example.com' for 'katrin@example.com'" do
      query = 'katrin@example.com'
      results = Services::Search.new(query).call

      expect(results).to eq([user])
    end

    it "finds user with secondary email='lisbethmarianne@example.com' for 'lisbethmarianne@example.com'" do
      query = 'lisbethmarianne@example.com'
      results = Services::Search.new(query).call

      expect(results).to eq([user])
    end
  end

  context "search for homepage" do
    it "finds organization with homepage='http://rubymonstas.org/' for 'http://rubymonstas.org/'" do
      query = 'http://rubymonstas.org/'
      results = Services::Search.new(query).call

      expect(results).to eq([organization])
    end
  end

  context "search for repository slug" do
    it "finds repository with slug='rubymonstas/diversitytickets' for 'rubymonstas/diversitytickets'" do
      query = 'rubymonstas/diversitytickets'
      results = Services::Search.new(query).call

      expect(results).to eq([repository])
    end
  end

  context "search for build slug" do
    it "finds build with slug='rubymonstas/diversitytickets#567' for 'rubymonstas/diversitytickets#567'" do
      query = 'rubymonstas/diversitytickets#567'
      results = Services::Search.new(query).call

      expect(results).to eq([build])
    end
  end

  context "search for job slug" do
    it "finds job with slug='rubymonstas/diversitytickets#567.1' for 'rubymonstas/diversitytickets#567.1'" do
      query = 'rubymonstas/diversitytickets#567.1'
      results = Services::Search.new(query).call

      expect(results).to eq([job])
    end
  end

  context "search with github url" do
    it "finds user with login='lisbethmarianne' for 'https://github.com/lisbethmarianne'" do
      query = 'https://github.com/lisbethmarianne'
      results = Services::Search.new(query).call

      expect(results).to eq([user])
    end

    it "finds organization with login='rubymonstas' for 'https://github.com/rubymonstas'" do
      query = 'https://github.com/rubymonstas'
      results = Services::Search.new(query).call

      expect(results).to eq([organization])
    end

    it "finds repository with slug='rubymonstas/diversitytickets' for 'https://github.com/rubymonstas/diversitytickets'" do
      query = 'https://github.com/rubymonstas/diversitytickets'
      results = Services::Search.new(query).call

      expect(results).to eq([repository])
    end
  end

  context "search with travis-ci url" do
    it "finds user with login='lisbethmarianne' for 'https://travis-ci.com/profile/lisbethmarianne'" do
      query = 'https://travis-ci.com/profile/lisbethmarianne'
      results = Services::Search.new(query).call

      expect(results).to eq([user])
    end

    it "finds organization with login='rubymonstas' for 'https://travis-ci.com/profile/rubymonstas'" do
      query = 'https://travis-ci.com/profile/rubymonstas'
      results = Services::Search.new(query).call

      expect(results).to eq([organization])
    end

    it "finds repository with slug='rubymonstas/diversitytickets' for 'https://travis-ci.com/rubymonstas/diversitytickets'" do
      query = 'https://travis-ci.com/rubymonstas/diversitytickets'
      results = Services::Search.new(query).call

      expect(results).to eq([repository])
    end

    it "finds build with id=6397 for 'https://travis-ci.com/rubymonstas/diversitytickets/builds/6397'" do
      query = 'https://travis-ci.com/rubymonstas/diversitytickets/builds/6397'
      results = Services::Search.new(query).call

      expect(results).to eq([build])
    end

    it "finds job with id=35465 for 'https://travis-ci.com/rubymonstas/diversitytickets/jobs/35465'" do
      query = 'https://travis-ci.com/rubymonstas/diversitytickets/jobs/35465'
      results = Services::Search.new(query).call

      expect(results).to eq([job])
    end
  end
end
