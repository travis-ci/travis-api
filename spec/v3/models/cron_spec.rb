require 'timecop'

describe Travis::API::V3::Models::Cron do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:branch) { Travis::API::V3::Models::Branch.create(repository: repo, name: 'cron test') }

  describe "next build time is calculated correctly on year changes" do

    before do
      Timecop.travel(DateTime.new(2015, 12, 31, 16))
    end

    after do
      Timecop.return
    end

    it "for daily builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'daily', disable_by_build: false)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 1, 1, 16)
      build.destroy
      cron.destroy
    end

    it "for weekly builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'weekly', disable_by_build: false)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 1, 7, 16)
      build.destroy
      cron.destroy
    end

    it "for monthly builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'monthly', disable_by_build: false)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 1, 31, 16)
      build.destroy
      cron.destroy
    end

  end

  describe "push build is ignored if disable by build is false" do

    before do
      Timecop.travel(DateTime.new(2015, 12, 31, 16))
    end

    after do
      Timecop.return
    end

    it "for daily builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'daily', disable_by_build: false)
      cron_build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      push_build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'push')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 1, 1, 16)
      cron_build.destroy
      push_build.destroy
      cron.destroy
    end

    it "for weekly builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'weekly', disable_by_build: false)
      cron_build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      push_build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'push')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 1, 7, 16)
      cron_build.destroy
      push_build.destroy
      cron.destroy
    end

    it "for monthly builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'monthly', disable_by_build: false)
      cron_build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      push_build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'push')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 1, 31, 16)
      cron_build.destroy
      push_build.destroy
      cron.destroy
    end

  end

  describe "disable by build works with build" do

    before do
      Timecop.travel(DateTime.new(2015, 12, 31, 16))
    end

    after do
      Timecop.return
    end

    it "for daily builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'daily', disable_by_build: true)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'push')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 1, 2, 16)
      build.destroy
      cron.destroy
    end

    it "for weekly builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'weekly', disable_by_build: true)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'push')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 1, 14, 16)
      build.destroy
      cron.destroy
    end

    it "for monthly builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'monthly', disable_by_build: true)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'push')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 2, 29, 16) # it's a leap year :-D
      build.destroy
      cron.destroy
    end

  end

  describe "disable by build works without build" do

    before do
      Timecop.travel(DateTime.new(2015, 12, 31, 16))
    end

    after do
      Timecop.return
    end

    it "for daily builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'daily', disable_by_build: true)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 1, 1, 16)
      build.destroy
      cron.destroy
    end

    it "for weekly builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'weekly', disable_by_build: true)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 1, 7, 16)
      build.destroy
      cron.destroy
    end

    it "for monthly builds" do
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'monthly', disable_by_build: true)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      expect(cron.next_enqueuing).to be == DateTime.new(2016, 1, 31, 16)
      build.destroy
      cron.destroy
    end

  end

  describe "build starts now if next build time is in the past" do

    before do
      # nothing, this time
      # time freeze is performed in examples
    end

    after do
      Timecop.return
    end

    it "for daily builds with disable_by_build true" do
      Timecop.travel(DateTime.new(2015, 12, 31, 16))
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'daily', disable_by_build: true)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      Timecop.freeze(DateTime.new(2016, 1, 1, 19))
      expect(cron.next_enqueuing).to be == DateTime.now
      build.destroy
      cron.destroy
    end

    it "for daily builds with disable_by_build false" do
      Timecop.travel(DateTime.new(2015, 12, 31, 16))
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'daily', disable_by_build: false)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      Timecop.freeze(DateTime.new(2016, 1, 1, 19))
      expect(cron.next_enqueuing).to be == DateTime.now
      build.destroy
      cron.destroy
    end

    it "for weekly builds with disable_by_build true" do
      Timecop.travel(DateTime.new(2015, 12, 31, 16))
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'weekly', disable_by_build: true)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      Timecop.freeze(DateTime.new(2016, 1, 7, 19))
      expect(cron.next_enqueuing).to be == DateTime.now
      build.destroy
      cron.destroy
    end

    it "for weekly builds with disable_by_build false" do
      Timecop.travel(DateTime.new(2015, 12, 31, 16))
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'weekly', disable_by_build: false)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      Timecop.freeze(DateTime.new(2016, 1, 7, 19))
      expect(cron.next_enqueuing).to be == DateTime.now
      build.destroy
      cron.destroy
    end

    it "for monthly builds with disable_by_build true" do
      Timecop.travel(DateTime.new(2015, 12, 31, 16))
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'monthly', disable_by_build: true)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      Timecop.freeze(DateTime.new(2016, 1, 31, 19))
      expect(cron.next_enqueuing).to be == DateTime.now
      build.destroy
      cron.destroy
    end

    it "for monthly builds with disable_by_build false" do
      Timecop.travel(DateTime.new(2015, 12, 31, 16))
      cron = Travis::API::V3::Models::Cron.create(branch_id: branch.id, interval: 'monthly', disable_by_build: false)
      build = Travis::API::V3::Models::Build.create(:repository_id => repo.id, :branch_name => branch.name, :event_type => 'cron')
      Timecop.freeze(DateTime.new(2016, 1, 31, 19))
      expect(cron.next_enqueuing).to be == DateTime.now
      build.destroy
      cron.destroy
    end

  end

end
