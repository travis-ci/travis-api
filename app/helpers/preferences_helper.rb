module PreferencesHelper
  def keep_netrc
    self.preferences.fetch('keep_netrc', true)
  end

  def set_keep_netrc(bool)
    self.preferences['keep_netrc'] = bool
    self.save!
  end
end
