require 'spec_helper'

describe Url do
  include Support::ActiveRecord

  subject { Url.create(:url => "http://example.com") }

  describe ".shorten" do
    it "creates a new Url object if the url has not been shortened" do
      expect { Url.shorten("http://example.com") }.to change(Url, :count).from(0).to(1)
    end

    it "retrieves a Url which has already been shortened" do
      Url.shorten("http://example.com")
      expect { Url.shorten("http://example.com") }.not_to change(Url, :count)
    end
  end

  describe "#code" do
    it "sets the code automatically" do
      subject.code.should_not be_nil
    end
  end

  describe "#short_url" do
    it "returns the full short url" do
      subject.short_url.should match(%r(^http://trvs.io/\w{10}$))
    end
  end

end
