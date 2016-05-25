require 'spec_helper'

describe Permission do
  include Support::ActiveRecord

  describe 'by_roles' do
    before :each do
      Permission::ROLES.each { |role| Permission.create!(role => true) }
    end

    it 'returns matching permissions if two roles given as symbols' do
      Permission.by_roles([:admin, :pull]).size.should == 2
    end

    it 'returns a single permission if one role given' do
      Permission.by_roles('admin').size.should == 1
    end

    it 'returns an empty scope if no roles given' do
      Permission.by_roles('').size.should == 0
    end
  end
end
