require 'spec_helper'

describe Annotation do
  include Support::ActiveRecord

  let(:annotation) { Factory.build(:annotation) }

  describe 'validations' do
    it 'only allows http or https URLs' do
      annotation.url = 'ftp://travis-ci.org'
      annotation.save.should be_false
      annotation.errors[:url].first.should match(/scheme/)
    end

    it 'only allows valid URLs' do
      annotation.url = 'http://travis-ci.org:80b/'
      annotation.save.should be_false
      annotation.errors[:url].first.should match(/invalid/)
    end
  end
end
