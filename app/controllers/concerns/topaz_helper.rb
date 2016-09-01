module TopazHelper

  def builds_provided_for(owner)
    Travis::DataStores.topaz.builds_provided_for(owner.id).try(:to_i)
  end
end