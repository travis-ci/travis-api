class Build < ApplicationRecord
  class Config < ApplicationRecord
    self.table_name = :build_configs
  end

  include ConfigMethods
  include StateDisplay
  include ConfigDisplay

  belongs_to :owner,    polymorphic: true
  belongs_to :repository
  belongs_to :commit
  belongs_to :request
  has_many   :jobs,     as: :source

  scope :not_finished,    -> { where(state: %w[started received queued created]).sort_by {|build|
    %w[started received queued created].index(build.state.to_s) } }
  scope :finished,        -> { where(state: %w[finished passed failed errored canceled]).order('id DESC') }

  def next
    repository.builds.where("id > ?", id).first
  end

  def not_finished?
    %w[started received queued created].include? state
  end

  def previous
    repository.builds.where("id < ?", id).last
  end
end