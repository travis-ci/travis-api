class CachesController < ApplicationController
  def index
    @caches = Travis::Services::Repository::Caches::Find.call
  end

  def delete

  end
end