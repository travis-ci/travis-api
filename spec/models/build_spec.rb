require 'rails_helper'

RSpec.describe Build, type: :model do
  describe '#next' do
    let!(:repository)       { create(:repository) }
    let!(:other_repository) { create(:repository) }
    let!(:build)            { create(:build, repository: repository, id: 4) }
    let!(:next_build)       { create(:build, repository: repository, id: 6) }
    let!(:unrelated_build)  { create(:build, repository: other_repository, id: 5) }
    let!(:unrelated_build)  { create(:build, repository: other_repository, id: 7) }

    it 'finds next build from the same repository' do
      expect(build.next).to eql next_build
      expect(build.next.repository).to eql repository
    end

    it 'returns nil if there is no next build from the same repository' do
      expect(next_build.next).to eql nil
    end
  end

  describe '#previous' do
    let!(:repository)       { create(:repository) }
    let!(:other_repository) { create(:repository) }
    let!(:build)            { create(:build, repository: repository, id: 4) }
    let!(:previous_build)   { create(:build, repository: repository, id: 2) }
    let!(:unrelated_build)  { create(:build, repository: other_repository, id: 3) }
    let!(:unrelated_build)  { create(:build, repository: other_repository, id: 1) }

    it 'finds previous build from the same repository' do
      expect(build.previous).to eql previous_build
      expect(build.previous.repository).to eql repository
    end

    it 'returns nil if there is no previous build from the same repository' do
      expect(previous_build.previous).to eql nil
    end
  end
end
