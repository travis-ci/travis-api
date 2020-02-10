module Test
  module Services
    extend Travis::Services::Registry

    class DoStuff < Travis::Services::Base
      attr_reader :current_user, :params

      def initialize(current_user, params)
        @current_user, @params = current_user, params
      end
    end
  end

  class Foo
    include Travis::Services::Helpers
  end
end

describe Travis::Services::Helpers do
  include Travis::Testing::Stubs

  let(:object) { Test::Foo.new }

  before :each do
    Travis.stubs(:services).returns(Test::Services)
    Test::Services.add(:do_stuff, Test::Services::DoStuff)
  end

  describe 'service' do
    it 'given :foo as a type and :stuff as a name it returns an instance of Foo::Stuff' do
      expect(object.service(:do_stuff, {})).to be_instance_of(Test::Services::DoStuff)
    end

    it 'passes the given user' do
      expect(object.service(:do_stuff, user).current_user).to eq(user)
    end

    it 'passes the given params' do
      params = { some: :thing }
      expect(object.service(:do_stuff, params).params).to eq(params)
    end

    it 'defaults params to {}' do
      expect(object.service(:do_stuff).params).to eq({})
    end

    it 'defaults the user to the current user if the object responds to :current_user' do
      object.stubs(:current_user).returns(user)
      expect(object.service(:do_stuff, {}).current_user).to eq(user)
    end

    it 'defaults the user to nil if the object does not respond to :current_user' do
      expect(object.service(:do_stuff, {}).current_user).to be_nil
    end
  end
end
