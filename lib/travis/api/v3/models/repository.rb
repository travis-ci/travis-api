module Travis::API::V3
  class Models::Repository < Model
    has_many :commits,     dependent: :delete_all
    has_many :requests,    dependent: :delete_all
    has_many :branches,    dependent: :delete_all, order: 'branches.id DESC'.freeze
    has_many :builds,      dependent: :delete_all, order: 'builds.id DESC'.freeze
    has_many :permissions, dependent: :delete_all
    has_many :users,       through:   :permissions

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
  end
end
