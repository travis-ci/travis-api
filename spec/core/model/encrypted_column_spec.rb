require 'spec_helper'

class Travis::Model < ActiveRecord::Base
  describe EncryptedColumn do
    def encode str
      Base64.strict_encode64 str
    end

    let(:options){ { key: 'secret-key' } }
    let(:column) { EncryptedColumn.new(options) }
    let(:iv)     { 'a' * 16 }
    let(:aes)    { stub('aes', :final => '') }

    describe '#encrypt?' do
      it 'does not encrypt if given data is empty' do
        column.encrypt?(nil).should be_false
        column.encrypt?('').should be_false
      end

      context 'when disabled' do
        let(:options) { { disable: true, key: 'secret-key' } }
        it 'does not encrypt' do
          column.encrypt?('--ENCR--abc').should be_false
        end
      end
    end

    describe '#decrypt?' do
      it 'does not decrypt if given data is empty' do
        column.decrypt?(nil).should be_false
        column.decrypt?('').should be_false
      end
    end

    context 'when encryption is disabled' do
      before { column.stubs :encrypt? => false }

      describe '#dump' do
        it 'does not encrypt data' do
          column.dump('123qwe').should == '123qwe'
        end
      end
    end

    it 'allows to pass use_prefix as an option' do
      EncryptedColumn.new(use_prefix: true).use_prefix?.should be_true
    end

    it 'allows to pass key as an option' do
      EncryptedColumn.new(key: 'foobarbaz').key.should == 'foobarbaz'

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

            column.load(data).should == 'decrypted'
          end

          it 'removes prefix if prefix is still used' do
            data = encode "to-decrypt#{iv}"
            data = "#{column.prefix}#{data}"

            column.expects(:create_aes).with(:decrypt, 'secret-key', iv).returns(aes)
            aes.expects(:update).with('to-decrypt').returns('decrypted')

            column.load(data).should == 'decrypted'
          end
        end

        describe '#dump' do
          it 'attaches iv to encrypted string' do
            column.stubs(:iv => iv)
            column.expects(:create_aes).with(:encrypt, 'secret-key', iv).returns(aes)
            aes.expects(:update).with('to-encrypt').returns('encrypted')

            column.dump('to-encrypt').should == encode("encrypted#{iv}")
          end
        end
      end

      context 'when prefix usage is enabled' do
        before { column.stubs :use_prefix? => true }

        describe '#load' do
          it 'does not decrypt data if prefix is not used' do
            data = 'abc'

            column.load(data).should == data
          end

          it 'decrypts data if prefix is used' do
            data = encode "to-decrypt#{iv}"
            data = "#{column.prefix}#{data}"

            column.expects(:create_aes).with(:decrypt, 'secret-key', iv).returns(aes)
            aes.expects(:update).with('to-decrypt').returns('decrypted')

            column.load(data).should == 'decrypted'
          end
        end

        describe '#dump' do
          it 'attaches iv and prefix to encrypted string' do
            column.stubs(:iv => iv)
            column.expects(:create_aes).with(:encrypt, 'secret-key', iv).returns(aes)
            aes.expects(:update).with('to-encrypt').returns('encrypted')

            result = encode "encrypted#{iv}"
            column.dump('to-encrypt').should == "#{column.prefix}#{result}"
          end
        end
      end
    end
  end
end
