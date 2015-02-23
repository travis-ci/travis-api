module Travis::API::V3
  class Models::Repository < Model
    has_many :commits,     dependent: :delete_all
    has_many :requests,    dependent: :delete_all
    has_many :builds,      dependent: :delete_all
    has_many :permissions, dependent: :delete_all
    has_many :users,       through:   :permissions

    belongs_to :owner, polymorphic: true

    has_one :last_build,
      class_name: 'Travis::API::V3::Models::Build'.freeze,
      order:      'id DESC'.freeze

    def slug
      @slug ||= "#{owner_name}/#{name}"
    end

    def last_build_on(branch)
      builds.order('id DESC'.freeze).where(branch: branch, event_type: 'push'.freeze).first
    end
  end
end
