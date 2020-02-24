describe Travis::Api::App::Extensions::SubclassTracker do
  let!(:root) { Sinatra.new { register Travis::Api::App::Extensions::SubclassTracker } }
  let!(:left) { Class.new(root) }
  let!(:right) { Class.new(root) }
  let!(:sub1) { Class.new(right) }
  let!(:sub2) { Class.new(right) }

  it 'tracks direct subclasses' do
    classes = root.direct_subclasses
    expect(classes.size).to eq(2)
    expect(classes).to include(left)
    expect(classes).to include(right)
  end

  it 'tracks leaf subclasses' do
    classes = root.subclasses
    expect(classes.size).to eq(3)
    expect(classes).to include(left)
    expect(classes).to include(sub1)
    expect(classes).to include(sub2)
  end

  it 'tracks subclasses of subclasses properly' do
    classes = right.subclasses
    expect(classes.size).to eq(2)
    expect(classes).to include(sub1)
    expect(classes).to include(sub2)
  end
end
