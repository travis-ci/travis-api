module Scenario
  class << self
    def default

      Organization.table_name = 'organizations'
      Repository.table_name = 'repositories'
      User.table_name = 'users'
      Token.table_name = 'tokens'
      SslKey.table_name = 'ssl_keys'
      Commit.table_name = 'commits'
      Request.table_name = 'requests'
      Job.table_name = 'jobs'
      Url.table_name = 'urls'
      Build.table_name = 'builds'
      BuildBackup.table_name = 'build_backups'
      Broadcast.table_name = 'broadcasts'
      Branch.table_name = 'branches'
      OwnerGroup.table_name = 'owner_groups'
      Travis::API::V3::Models::Branch.table_name = 'branches'
      Job::Test.table_name = 'jobs'
      Permission.table_name = 'permissions'
      Membership.table_name = 'memberships'
      minimal, enginex, sharedrepo = repositories :minimal, :enginex, :sharedrepo
      sharedrepo_permission = permissions :sharedrepo_permission

      build :repository => minimal,
            :owner => minimal.owner,
            :owner_type => minimal.owner.class.name,
            :number => 1,
            :config => { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['test/Gemfile.rails-2.3.x', 'test/Gemfile.rails-3.0.x'] },
            :state  => 'failed',
            :started_at => '2010-11-12 12:00:00',
            :finished_at => '2010-11-12 12:00:10',
            :commit => {
              :commit => '1a738d9d6f297c105ae2',
              :ref => 'refs/heads/develop',
              :branch => 'master',
              :message => 'add Gemfile',
              :committer_name => 'Sven Fuchs',
              :committer_email => 'svenfuchs@artweb-design.de',
              :committed_at => '2010-11-12 11:50:00',
            },
            :jobs => [
              { :owner => minimal.owner, :owner_type => 'User', :worker => 'ruby3.worker.travis-ci.org:travis-ruby-4', :source_type => 'Build' }
            ]
      
      build :repository => minimal,
            :owner => minimal.owner,
            :owner_type => minimal.owner.class.name,
            :number => 2,
            :config => { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['test/Gemfile.rails-2.3.x', 'test/Gemfile.rails-3.0.x'] },
            :state  => 'passed',
            :started_at => '2010-11-12 12:30:00',
            :finished_at => '2010-11-12 12:30:20',
            :commit => {
              :commit => '91d1b7b2a310131fe3f8',
              :ref => 'refs/heads/master',
              :branch => 'master',
              :message => 'Bump to 0.0.22',
              :committer_name => 'Sven Fuchs',
              :committer_email => 'svenfuchs@artweb-design.de',
              :committed_at => '2010-11-12 12:25:00',
            },
            :jobs => [
              { :owner => minimal.owner, :owner_type => minimal.owner.class.name, :worker => 'ruby3.worker.travis-ci.org:travis-ruby-4' , source_type: 'Build'}
            ]

      build :repository => minimal,
            :owner => minimal.owner,
            :owner_type => minimal.owner.class.name,
            :number => '3',
            :config => { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['test/Gemfile.rails-2.3.x', 'test/Gemfile.rails-3.0.x'] },
            :state  => 'configured',
            :started_at => '2010-11-12 13:00:00',
            :finished_at => nil,
            :commit => {
              :commit => 'add057e66c3e1d59ef1f',
              :ref => 'refs/heads/master',
              :branch => 'master',
              :message => 'unignore Gemfile.lock',
              :committed_at => '2010-11-12 12:55:00',
              :committer_name => 'Sven Fuchs',
              :committer_email => 'svenfuchs@artweb-design.de',
            },
            :jobs => [
              { :owner => minimal.owner, :owner_type => minimal.owner.class.name, :worker => 'ruby3.worker.travis-ci.org:travis-ruby-5' , source_type: 'Build'},
              { :owner => minimal.owner, :owner_type => minimal.owner.class.name, :worker => 'ruby3.worker.travis-ci.org:travis-ruby-6' , source_type: 'Build'},
              { :owner => minimal.owner, :owner_type => minimal.owner.class.name, :worker => 'ruby3.worker.travis-ci.org:travis-ruby-7' , source_type: 'Build'},
              { :owner => minimal.owner, :owner_type => minimal.owner.class.name, :worker => 'ruby3.worker.travis-ci.org:travis-ruby-8' , source_type: 'Build'}
            ]

      build :repository => sharedrepo,
            :owner => sharedrepo.owner,
            :owner_type => sharedrepo.owner.class.name,
            :number => 1,
            :config => { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['test/Gemfile.rails-2.3.x', 'test/Gemfile.rails-3.0.x'] },
            :state  => 'failed',
            :started_at => '2010-11-12 12:00:00',
            :finished_at => '2010-11-12 12:00:10',
            :commit => {
              :commit => '1a738d9d6f297c105ae2',
              :ref => 'refs/heads/develop',
              :branch => 'master',
              :message => 'add Gemfile',
              :committer_name => 'Sven Fuchs',
              :committer_email => 'svenfuchs@artweb-design.de',
              :committed_at => '2010-11-12 11:50:00',
            },
            :jobs => [
              { :owner => sharedrepo.owner, :owner_type => sharedrepo.owner.class.name, :worker => 'ruby3.worker.travis-ci.org:travis-ruby-9' , source_type: 'Build'}
            ]

      build :repository => enginex,
            :owner => enginex.owner,
            :owner_type => enginex.owner.class.name,
            :number => 1,
            :state  => 'fails',
            :started_at => '2010-11-11 12:00:00',
            :finished_at => '2010-11-11 12:00:05',
            :commit => {
              :commit => '565294c05913cfc23230',
              :branch => 'master',
              :ref => 'refs/heads/master',
              :message => 'Update Capybara',
              :author_name => 'Jose Valim',
              :author_email => 'jose@email.example.com',
              :committer_name => 'Jose Valim',
              :committer_email => 'jose@email.example.com',
              :committed_at => '2010-11-11 11:55:00',
            },
            :jobs => [
              { :owner => enginex.owner, :owner_type => enginex.owner.class.name, :worker => 'ruby3.worker.travis-ci.org:travis-ruby-4' , source_type: 'Build'}
            ]

      [minimal, enginex]
    end

    def repositories(*names)
      names.map { |name|
        repo = FactoryBot.create(name)
        repo.create_key
        repo
      }
    end

    def permissions(*names)
      names.map { |name|
        perm = FactoryBot.create(name)
        perm
      }
    end

    def build(attributes)
      Build.table_name = 'builds'
      commit = attributes.delete(:commit)
      jobs  = attributes.delete(:jobs)
      commit = FactoryBot.create(:commit, commit)

      build  = FactoryBot.create(:build, attributes.merge(:commit => commit))
      build.matrix.each_with_index do |job, ix|
        job.update!(jobs[ix] || {})
      end

      if build.finished?
        keys = %w(id number state finished_at started_at)
        attributes = keys.inject({}) { |result, key| result.merge(:"last_build_#{key}" => build.send(key)) }
        build.repository.update!(attributes)
      end
    end
  end
end

