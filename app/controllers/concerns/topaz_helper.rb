module TopazHelper

  def builds_provided_for(owner)
    Travis::DataStores.topaz.builds_provided_for(owner.id).try(:to_i)
  end

  def update_topaz(owner, builds)
    event = {
      timestamp: Time.now,
      owner: {
        id: owner.id,
        name: owner.name,
        login: owner.login,
        type: owner.class.name
      },
      data: {
        trial_builds_added: builds.to_i,
        previous_builds: builds_provided_for(owner)
      },
      type: :trial_builds_added
    }
    Travis::DataStores.topaz.update(event)
  end
end