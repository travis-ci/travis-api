describe Permission do
  describe 'by_roles' do
    before :each do
      Permission::ROLES.each { |role| Permission.create!(role => true) }
    end

    it 'returns matching permissions if two roles given as symbols' do
      expect(Permission.by_roles([:admin, :pull]).size).to eq(3)
    end

    it 'returns a single permission if one role given' do
      expect(Permission.by_roles('admin').size).to eq(1)
    end

    it 'returns an empty scope if no roles given' do
      expect(Permission.by_roles('').size).to eq(0)
    end
  end
end
