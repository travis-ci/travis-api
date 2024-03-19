describe Url do
  subject { Url.create(url: "http://example.com") }

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
      expect(subject.code).not_to be_nil
    end
  end

  describe "#short_url" do
    it "returns the full short url" do
      expect(subject.short_url).to match(%r(^http://trvs.io/\w{10}$))
    end
  end

end
