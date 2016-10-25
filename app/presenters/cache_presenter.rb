class CachePresenter < SimpleDelegator
  def initialize(caches, view)
    @caches = caches
    @view = view
    super(@caches)
  end

  def h
    @view
  end
end
