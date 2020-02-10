class Travis::Model < ActiveRecord::Base
  describe EncryptedColumn do
    def encode str
      Base64.strict_encode64 str
    end

    let(:options){ { key: 'secret-key' } }
    let(:column) { EncryptedColumn.new(options) }
    let(:iv)     { 'a' * 16 }
    let(:aes)    { double('aes', :final => '') }

    describe '#encrypt?' do
      it 'does not encrypt if given data is empty' do
        expect(column.encrypt?(nil)).to be false
        expect(column.encrypt?('')).to be false
      end

      context 'when disabled' do
        let(:options) { { disable: true, key: 'secret-key' } }
        it 'does not encrypt' do
          expect(column.encrypt?('--ENCR--abc')).to be false
        end
      end
    end

    describe '#decrypt?' do
      it 'does not decrypt if given data is empty' do
        expect(column.decrypt?(nil)).to be false
        expect(column.decrypt?('')).to be false
      end
    end

    context 'when encryption is disabled' do
      before { column.stubs :encrypt? => false }

      describe '#dump' do
        it 'does not encrypt data' do
          expect(column.dump('123qwe')).to eq('123qwe')
        end
      end
    end

    it 'allows to pass use_prefix as an option' do
      expect(EncryptedColumn.new(use_prefix: true).use_prefix?).to be true
    end

    it 'allows to pass key as an option' do
      expect(EncryptedColumn.new(key: 'foobarbaz').key).to eq('foobarbaz')

    end

    context 'when encryption is enabled' do
      before { column.stubs :encrypt? => true }

      context 'when prefix usage is disabled' do
        before { column.stubs :use_prefix? => false }

        describe '#load' do
          it 'decrypts data even with no prefix' do
            data = encode "to-decrypt#{iv}"

            column.expects(:create_aes).with(:decrypt, 'secret-key', iv).returns(aes)
            aes.expects(:update).with('to-decrypt').returns('decrypted')

            expect(column.load(data)).to eq('decrypted')
          end

          it 'removes prefix if prefix is still used' do
            data = encode "to-decrypt#{iv}"
            data = "#{column.prefix}#{data}"

            column.expects(:create_aes).with(:decrypt, 'secret-key', iv).returns(aes)
            aes.expects(:update).with('to-decrypt').returns('decrypted')

            expect(column.load(data)).to eq('decrypted')
          end
        end

        describe '#dump' do
          it 'attaches iv to encrypted string' do
            column.stubs(:iv => iv)
            column.expects(:create_aes).with(:encrypt, 'secret-key', iv).returns(aes)
            aes.expects(:update).with('to-encrypt').returns('encrypted')

            expect(column.dump('to-encrypt')).to eq(encode("encrypted#{iv}"))
          end
        end
      end

      context 'when prefix usage is enabled' do
        before { column.stubs :use_prefix? => true }

        describe '#load' do
          it 'does not decrypt data if prefix is not used' do
            data = 'abc'

            expect(column.load(data)).to eq(data)
          end

          it 'decrypts data if prefix is used' do
            data = encode "to-decrypt#{iv}"
            data = "#{column.prefix}#{data}"

            column.expects(:create_aes).with(:decrypt, 'secret-key', iv).returns(aes)
            aes.expects(:update).with('to-decrypt').returns('decrypted')

            expect(column.load(data)).to eq('decrypted')
          end
        end

        describe '#dump' do
          it 'attaches iv and prefix to encrypted string' do
            column.stubs(:iv => iv)
            column.expects(:create_aes).with(:encrypt, 'secret-key', iv).returns(aes)
            aes.expects(:update).with('to-encrypt').returns('encrypted')

            result = encode "encrypted#{iv}"
            expect(column.dump('to-encrypt')).to eq("#{column.prefix}#{result}")
          end
        end
      end
    end
  end
end
