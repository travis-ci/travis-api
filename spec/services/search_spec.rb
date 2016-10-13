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

  def search(query)
    Services::Search.new(query).call
  end

  context "explicit search (search by type and id)" do
    it "finds repository with id=416 for 'repo 416'" do
      expect(search('repo 416')).to eq([repository])
    end

    it "finds repository with id=416 for 'repository 416'" do
      expect(search('repository 416')).to eq([repository])
    end

    it "finds request with id=4567 for 'request 4567'" do
      expect(search('request 4567')).to eq([request])
    end

    it "finds build with id=6397 for 'build 6397'" do
      expect(search('build 6397')).to eq([build])
    end

    it "finds job with id=35465 for 'job 35465'" do
      expect(search('job 35465')).to eq([job])
    end

    it "finds user with id=162 for 'user 162'" do
      expect(search('user 162')).to eq([user])
    end

    it "finds user with github_id=12324 for 'user 12324'" do
      expect(search('user 12324')).to eq([user2])
    end

    it "finds organization with id=46 for 'organization 46'" do
      expect(search('organization 46')).to eq([organization])
    end

    it "finds user with github_id=9267 for 'organization 9267'" do
      expect(search('organization 9267')).to eq([organization2])
    end
  end

  context "search for login" do
    it "finds user with login='lisbethmarianne' for 'lisbethmarianne'" do
      expect(search('lisbethmarianne')).to eq([user])
    end

    it "finds organization with login='rubymonstas' for 'rubymonstas'" do
      expect(search('rubymonstas')).to eq([organization])
    end

    it "finds organization with login='rubymonstas' for 'Rubymonstas'" do
      expect(search('Rubymonstas')).to eq([organization])
    end

    it "finds organization with login='travis-ci' as well as repo with name='travis-ci' for 'travis-ci'" do
      expect(search('travis-ci')).to include organization2
      expect(search('travis-ci')).to include repository2
    end
  end

  context "search for name" do
    it "finds user with name='Katrin' for 'Katrin'" do
      expect(search('Katrin')).to eq([user])
    end

    it "finds organization with name='Ruby Monstas' for 'Ruby Monstas'" do
      expect(search('Ruby Monstas')).to eq([organization])
    end

    it "finds organization with name='Ruby Monstas' for 'ruby monstas'" do
      expect(search('ruby monstas')).to eq([organization])
    end

    it "finds repository with name='diversitytickets' for 'diversitytickets'" do
      expect(search('diversitytickets')).to eq([repository])
    end
  end

  context "search for email" do
    it "finds user with email='katrin@example.com' for 'katrin@example.com'" do
      expect(search('katrin@example.com')).to eq([user])
    end

    it "finds user with secondary email='lisbethmarianne@example.com' for 'lisbethmarianne@example.com'" do
      expect(search('lisbethmarianne@example.com')).to eq([user])
    end
  end

  context "search for homepage" do
    it "finds organization with homepage='http://rubymonstas.org/' for 'http://rubymonstas.org/'" do
      expect(search('http://rubymonstas.org/')).to eq([organization])
    end
  end

  context "search for repository slug" do
    it "finds repository with slug='rubymonstas/diversitytickets' for 'rubymonstas/diversitytickets'" do
      expect(search('rubymonstas/diversitytickets')).to eq([repository])
    end
  end

  context "search for build slug" do
    it "finds build with slug='rubymonstas/diversitytickets#567' for 'rubymonstas/diversitytickets#567'" do
      expect(search('rubymonstas/diversitytickets#567')).to eq([build])
    end
  end

  context "search for job slug" do
    it "finds job with slug='rubymonstas/diversitytickets#567.1' for 'rubymonstas/diversitytickets#567.1'" do
      expect(search('rubymonstas/diversitytickets#567.1')).to eq([job])
    end
  end

  context "search with github url" do
    it "finds user with login='lisbethmarianne' for 'https://github.com/lisbethmarianne'" do
      expect(search('https://github.com/lisbethmarianne')).to eq([user])
    end

    it "finds user with login='lisbethmarianne' for 'https://github.com/LisbethMarianne'" do
      expect(search('https://github.com/LisbethMarianne')).to eq([user])
    end

    it "finds organization with login='rubymonstas' for 'https://github.com/rubymonstas'" do
      expect(search('https://github.com/rubymonstas')).to eq([organization])
    end

    it "finds repository with slug='rubymonstas/diversitytickets' for 'https://github.com/rubymonstas/diversitytickets'" do
      expect(search('https://github.com/rubymonstas/diversitytickets')).to eq([repository])
    end
  end

  context "search with travis-ci url" do
    it "finds user with login='lisbethmarianne' for 'https://travis-ci.com/profile/lisbethmarianne'" do
      expect(search('https://travis-ci.com/profile/lisbethmarianne')).to eq([user])
    end

    it "finds user with login='lisbethmarianne' for 'https://travis-ci.com/profile/LisbethMarianne'" do
      expect(search('https://travis-ci.com/profile/LisbethMarianne')).to eq([user])
    end

    it "finds organization with login='rubymonstas' for 'https://travis-ci.com/profile/rubymonstas'" do
      expect(search('https://travis-ci.com/profile/rubymonstas')).to eq([organization])
    end

    it "finds repository with slug='rubymonstas/diversitytickets' for 'https://travis-ci.com/rubymonstas/diversitytickets'" do
      expect(search('https://travis-ci.com/rubymonstas/diversitytickets')).to eq([repository])
    end

    it "finds build with id=6397 for 'https://travis-ci.com/rubymonstas/diversitytickets/builds/6397'" do
      expect(search('https://travis-ci.com/rubymonstas/diversitytickets/builds/6397')).to eq([build])
    end

    it "finds job with id=35465 for 'https://travis-ci.com/rubymonstas/diversitytickets/jobs/35465'" do
      expect(search('https://travis-ci.com/rubymonstas/diversitytickets/jobs/35465')).to eq([job])
    end
  end
end
