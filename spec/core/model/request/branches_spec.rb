require 'spec_helper'

describe Request::Branches do
  include Travis::Testing::Stubs

  let(:branches) { Request::Branches.new(request) }

  describe '#included?' do
    it 'defaults to true if no branches are included' do
      request.config['branches'] = { 'only' => nil }
      branches.included?('feature').should be_true
    end

    describe 'returns true if the included branches include the given branch' do
      it 'given as a string' do
        request.config['branches'] = { 'only' => 'feature' }
        branches.included?('feature').should be_true
      end

      it 'given as a comma separated list of branches' do
        request.config['branches'] = { 'only' => 'feature, develop' }
        branches.included?('feature').should be_true
      end

      it 'given as an array of branches' do
        request.config['branches'] = { 'only' => %w(feature develop) }
        branches.included?('feature').should be_true
      end
    end

    describe 'returns true if the given branch matches a pattern from the included branches' do
      it 'given as a string' do
        request.config['branches'] = { 'only' => '/^feature-\d+$/' }
        branches.included?('feature-42').should be_true
      end

      it 'given as a comma separated list of patterns' do
        request.config['branches'] = { 'only' => '/^feature-\d+$/,/^develop-\d+$/' }
        branches.included?('feature-42').should be_true
      end

      it 'given as an array of patterns' do
        request.config['branches'] = { 'only' => %w(/^feature-\d+$/ /^develop-\d+$/) }
        branches.included?('feature-42').should be_true
      end
    end

    describe 'returns false if the included branches do not include the given branch' do
      it 'given as a string' do
        request.config['branches'] = { 'only' => 'feature' }
        branches.included?('master').should be_false
      end

      it 'given as a comma separated list of branches' do
        request.config['branches'] = { 'only' => 'feature, develop' }
        branches.included?('master').should be_false
      end

      it 'given as an array of branches' do
        request.config['branches'] = { 'only' => %w(feature develop) }
        branches.included?('master').should be_false
      end
    end

    describe 'returns false if the given branch does not match any pattern from the included branches' do
      it 'given as a string' do
        request.config['branches'] = { 'only' => '/^feature-\d+$/' }
        branches.included?('master').should be_false
      end

      it 'given as a comma separated list of patterns' do
        request.config['branches'] = { 'only' => '/^feature-\d+$/,/^develop-\d+$/' }
        branches.included?('master').should be_false
      end

      it 'given as an array of patterns' do
        request.config['branches'] = { 'only' => %w(/^feature-\d+$/ /^develop-\d+$/) }
        branches.included?('master').should be_false
      end
    end
  end

  describe '#excluded?' do
    it 'defaults to false if no branches are excluded' do
      request.config['branches'] = { 'except' => nil }
      branches.excluded?('feature').should be_false
    end

    describe 'returns true if the excluded branches include the given branch' do
      it 'given as a string' do
        request.config['branches'] = { 'except' => 'feature' }
        branches.excluded?('feature').should be_true
      end

      it 'given as a comma separated list of branches' do
        request.config['branches'] = { 'except' => 'feature, develop' }
        branches.excluded?('feature').should be_true
      end

      it 'given as an array of branches' do
        request.config['branches'] = { 'except' => %w(feature develop) }
        branches.excluded?('feature').should be_true
      end
    end

    describe 'returns true if the given branch matches a pattern from the excluded branches' do
      it 'given as a string' do
        request.config['branches'] = { 'except' => '/^feature-\d+$/' }
        branches.excluded?('feature-42').should be_true
      end

      it 'given as a comma separated list of patterns' do
        request.config['branches'] = { 'except' => '/^feature-\d+$/,/^develop-\d+$/' }
        branches.excluded?('feature-42').should be_true
      end

      it 'given as an array of patterns' do
        request.config['branches'] = { 'except' => %w(/^feature-\d+$/ /^develop-\d+$/) }
        branches.excluded?('feature-42').should be_true
      end
    end

    describe 'returns false if the excluded branches do not include the given branch' do
      it 'given as a string' do
        request.config['branches'] = { 'except' => 'feature' }
        branches.excluded?('master').should be_false
      end

      it 'given as a comma separated list of branches' do
        request.config['branches'] = { 'except' => 'feature, develop' }
        branches.excluded?('master').should be_false
      end

      it 'given as an array of branches' do
        request.config['branches'] = { 'except' => %w(feature develop) }
        branches.excluded?('master').should be_false
      end
    end

    describe 'returns false if the given branch does not match any pattern from the excluded branches' do
      it 'given as a string' do
        request.config['branches'] = { 'except' => '/^feature-\d+$/' }
        branches.excluded?('master').should be_false
      end

      it 'given as a comma separated list of patterns' do
        request.config['branches'] = { 'except' => '/^feature-\d+$/,/^develop-\d+$/' }
        branches.excluded?('master').should be_false
      end

      it 'given as an array of patterns' do
        request.config['branches'] = { 'except' => %w(/^feature-\d+$/ /^develop-\d+$/) }
        branches.excluded?('master').should be_false
      end
    end
  end
end
