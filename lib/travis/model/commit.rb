require 'travis/model'

# Encapsulates a commit that a Build belongs to (and that a Github Request
# referred to).
class Commit < Travis::Model
  self.table_name = 'commits'
  include Travis::ScopeAccess

  has_one :request
  belongs_to :repository

  validates :commit, :branch, :committed_at, :presence => true

  def tag_name
    ref =~ %r(^refs/tags/(.*)$) && $1
  end

  def pull_request?
    ref =~ %r(^refs/pull/\d+/merge$)
  end

  def pull_request_number
    if pull_request? && (num = ref.scan(%r(^refs/pull/(\d+)/merge$)).flatten.first)
      num.to_i
    end
  end

  def range
    if pull_request?
      "#{request.base_commit}...#{request.head_commit}"
    elsif compare_url && compare_url =~ /\/([0-9a-f]+\^*\.\.\.[0-9a-f]+\^*$)/
      $1
    end
  end
end
