module Travis::API::V3
  class Models::Repository < Model
    has_many :commits,     dependent: :delete_all
    has_many :requests,    dependent: :delete_all
    has_many :branches,    dependent: :delete_all, order: 'branches.id DESC'.freeze
    has_many :builds,      dependent: :delete_all, order: 'builds.id DESC'.freeze
    has_many :permissions, dependent: :delete_all
    has_many :users,       through:   :permissions
    has_many :stars

    belongs_to :owner, polymorphic: true
    belongs_to :last_build, class_name: 'Travis::API::V3::Models::Build'.freeze

    has_one :default_branch,
      foreign_key: [:repository_id, :name],
      primary_key: [:id,  :default_branch],
      class_name:  'Travis::API::V3::Models::Branch'.freeze

    after_initialize do
      update_attributes! default_branch_name: 'master'.freeze unless default_branch_name
    end

    def slug
      @slug ||= "#{owner_name}/#{name}"
    end

    def default_branch_name
      read_attribute(:default_branch)
    end

    def default_branch_name=(value)
      write_attribute(:default_branch, value)
    end

    def default_branch
      super || branch(default_branch_name, create_without_build: true)
    end

    # Creates a branch object on the fly if it doesn't exist.
    #
    # Will not create a branch object if we don't have any builds for it unless
    # the create_without_build option is set to true.
    def branch(name, create_without_build: false)
      return nil    unless branch = branches.where(name: name).first_or_initialize
      return branch unless branch.new_record?
      return nil    unless create_without_build or branch.builds.any?
      branch.last_build = branch.builds.first
      branch.save!
      branch
    rescue ActiveRecord::RecordNotUnique
      branches.where(name: name).first
    end

    def id_default_branch
      [id, default_branch_name]
    end

    def send(name, *args, &block)
      if name == [:id, :default_branch]
        name = :id_default_branch
      end

      __send__(name, *args, &block)
    end

    def branches_overview
      result = overview_query.branches(self)

      # order by branch name
      result.sort! { |a,b| a.branch <=> b.branch }

      passed = Hash.new(0)
      all    = Hash.new(0)

      result.each do |builds|
        passed[builds.branch_name] += builds.count.to_i if builds.state == "passed"
        all[builds.branch_name] += builds.count.to_i
      end

      data = {}

      # list default branch first
      default_branch = self.default_branch.name
      insert_guarded(data, passed, all, default_branch)
      passed.delete(default_branch)
      all.delete(default_branch)

      # after default branch all the other branches (in alphabetical order)
      all.each do |branch, sum|
        insert_guarded(data, passed, all, branch)
      end

      Models::Overview::Branches.new(data)
    end

    def build_duration_overview
      Models::Overview::BuildDuration.new(overview_query.build_duration(self))
    end

    def event_type_overview
      builds = overview_query.event_type(self)

      data = Hash.new { |hash, key| hash[key] = Hash.new(0) }

      builds.each_pair do |key, value|
        event_type = key[0]
        state      = key[1]
        data[event_type][state] = value
      end

      Models::Overview::EventType.new(data)
    end

    def recent_build_history_overview
      builds = overview_query.recent_build_history(self)

      data = Hash.new { |hash, key| hash[key] = Hash.new(0) }

      builds.each_pair do |key, value|
        created_at = key[0]
        state      = key[1]
        data[created_at.to_date][state] = value
      end

      Models::Overview::RecentBuildHistory.new(data)
    end

    def streak_overview
      result = overview_query.streak(self)

      start_of_streak = DateTime::Infinity.new
      build_count = 0

      result.each do |builds|
        start_of_streak = builds.created_at if builds.created_at < start_of_streak
        build_count = builds.count.to_i if builds.event_type == "push"
      end

      day_count = (build_count > 0) ? ((Time.now - start_of_streak)/(60*60*24)).floor : 0

      Models::Overview::Streak.new({days: day_count, builds: build_count})
    end

    private

    # for branches: to avoid division by zero
    def insert_guarded(data, passed, all, branch)
      data[branch] = passed[branch].to_f / all[branch].to_f unless all[branch].to_f == 0
    end

    def overview_query
      Queries::Overview.new({}, 'Overview')
    end
  end
end
