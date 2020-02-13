describe Commit do
  let(:commit) { Commit.new(:commit => '12345678') }

  describe 'pull_request_number' do
    context 'when commit is from pull request' do
      before { commit.ref = 'refs/pull/180/merge' }

      it 'returns pull request\'s number' do
        expect(commit.pull_request_number).to eq(180)
      end
    end

    context 'when commit is not from pull request' do
      before { commit.ref = 'refs/branch/master' }

      it 'returns nil' do
        expect(commit.pull_request_number).to be_nil
      end
    end
  end

  describe 'pull_request?' do
    it 'is false for a nil ref' do
      commit.ref = nil
      expect(commit.pull_request?).to be_falsey
    end

    it 'is false for a ref named ref/branch/master' do
      commit.ref = 'refs/branch/master'
      expect(commit.pull_request?).to be_falsey
    end

    it 'is false for a ref named ref/pull/180/head' do
      commit.ref = 'refs/pull/180/head'
      expect(commit.pull_request?).to be_falsey
    end

    it 'is true for a ref named ref/pull/180/merge' do
      commit.ref = 'refs/pull/180/merge'
      expect(commit.pull_request?).to be_truthy
    end
  end

  describe '#range' do
    context 'with compare_url present' do
      before { commit.compare_url = 'https://github.com/rails/rails/compare/ffaab2c4ffee...60790e852a4f' }

      it 'returns range' do
        expect(commit.range).to eq('ffaab2c4ffee...60790e852a4f')
      end
    end

    context 'with a compare_url with ^ in it' do
      before { commit.compare_url = 'https://github.com/rails/rails/compare/ffaab2c4ffee^...60790e852a4f' }

      it 'returns range' do
        expect(commit.range).to eq('ffaab2c4ffee^...60790e852a4f')
      end
    end

    context 'with invalid compare_url' do
      before { commit.compare_url = 'https://github.com/rails/rails/compare/ffaab2c4ffee.....60790e852a4f' }

      it 'returns nil' do
        expect(commit.range).to be_nil
      end
    end

    context 'without compare_url' do
      before { commit.compare_url = nil }

      it 'returns nil' do
        expect(commit.range).to be_nil
      end
    end

    context 'for a pull request' do
      before do
        commit.ref = 'refs/pull/1/merge'
        commit.request = Request.new(:base_commit => 'abcdef', :head_commit => '123456')
      end

      it 'returns range' do
        expect(commit.range).to eq('abcdef...123456')
      end
    end
  end
end
