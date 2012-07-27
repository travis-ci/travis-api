require 'spec_helper'

describe Travis::Api::App::Extensions::SubclassTracker do
  let!(:root) { Sinatra.new { register Travis::Api::App::Extensions::SubclassTracker } }
  let!(:left) { Class.new(root) }
  let!(:right) { Class.new(root) }
  let!(:sub1) { Class.new(right) }
  let!(:sub2) { Class.new(right) }

  it 'tracks direct subclasses' do
    classes = root.direct_subclasses
    classes.size.should == 2
    classes.should include(left)
    classes.should include(right)
  end

  it 'tracks leaf subclasses' do
    classes = root.subclasses
    classes.size.should == 3
    classes.should include(left)
    classes.should include(sub1)
    classes.should include(sub2)
  end

  it 'tracks subclasses of subclasses properly' do
    classes = right.subclasses
    classes.size.should == 2
    classes.should include(sub1)
    classes.should include(sub2)
  end
end
