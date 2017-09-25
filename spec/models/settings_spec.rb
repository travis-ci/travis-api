require 'rails_helper'

RSpec.describe Settings, type: :model do
  let!(:repository) { create(:repository) }
  let!(:repository_with_settings) { create(:repository, settings: {"build_pushes" => false, "timeout_hard_limit" => 12345}) }

  describe 'initialize Settings' do
    it 'correctly sets settings to default values for repo without settings' do
      expect(Settings.new(repository.settings).builds_only_with_travis_yml).to eql false
      expect(Settings.new(repository.settings).build_pushes).to eql true
      expect(Settings.new(repository.settings).build_pull_requests).to eql true
      expect(Settings.new(repository.settings).maximum_number_of_builds).to eql 0
      expect(Settings.new(repository.settings).auto_cancel_pushes).to eql false
      expect(Settings.new(repository.settings).auto_cancel_pull_requests).to eql false
    end

    it 'correctly sets settings for repo with settings' do
      expect(Settings.new(repository_with_settings.settings).builds_only_with_travis_yml).to eql false
      expect(Settings.new(repository_with_settings.settings).build_pushes).to eql false
      expect(Settings.new(repository_with_settings.settings).build_pull_requests).to eql true
      expect(Settings.new(repository_with_settings.settings).maximum_number_of_builds).to eql 0
      expect(Settings.new(repository_with_settings.settings).timeout_hard_limit).to eql 12345
    end
  end
end
