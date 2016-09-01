module TopazHelper

  def builds_provided_for(owner)
    Travis::DataStores.topaz.builds_provided_for(owner.id).try(:to_i)
  end

  def update_topaz(owner, builds_remaining, previous_builds)
    event = {
      timestamp: Time.now,
      owner: {
        id: owner.id,
        name: owner.name,
        login: owner.login,
        type: owner.class.name
      },
      data: {
        trial_builds_added: builds_remaining.to_i,
        previous_builds: previous_builds.to_i
      },
      type: :trial_builds_added
    }
    Travis::DataStores.topaz.update(event)
  end
end