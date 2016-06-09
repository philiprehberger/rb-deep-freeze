# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::DeepFreeze do
  describe '.deep_freeze' do
    it 'freezes nested hashes with inner strings and arrays' do
      obj = { a: { b: 'hello', c: [1, 'world'] } }
      described_class.deep_freeze(obj)

      expect(obj).to be_frozen
      expect(obj[:a]).to be_frozen
      expect(obj[:a][:b]).to be_frozen
      expect(obj[:a][:c]).to be_frozen
      expect(obj[:a][:c][1]).to be_frozen
    end

    it 'freezes nested arrays' do
      obj = [[1, 2], %w[a b], [{ key: 'val' }]]
      described_class.deep_freeze(obj)

      expect(obj).to be_frozen
      expect(obj[0]).to be_frozen
      expect(obj[1]).to be_frozen
      expect(obj[1][0]).to be_frozen
      expect(obj[2]).to be_frozen
      expect(obj[2][0]).to be_frozen
      expect(obj[2][0][:key]).to be_frozen
    end

    it 'handles circular references without infinite loop' do
      a = { name: 'a' }
      b = { name: 'b', ref: a }
      a[:ref] = b

      expect { described_class.deep_freeze(a) }.not_to raise_error
      expect(a).to be_frozen
      expect(b).to be_frozen
    end

    it 'excludes specified keys from freezing with except:' do
      obj = { keep: +'mutable', freeze_me: +'immutable', nested: { keep: +'also mutable' } }
      described_class.deep_freeze(obj, except: [:keep])

      expect(obj).to be_frozen
      expect(obj[:keep]).not_to be_frozen
      expect(obj[:freeze_me]).to be_frozen
      expect(obj[:nested][:keep]).not_to be_frozen
    end

    it 'freezes sets' do
      require 'set'
      obj = { tags: Set.new(%w[a b c]) }
      described_class.deep_freeze(obj)

      expect(obj[:tags]).to be_frozen
    end

    it 'does not error on already frozen objects' do
      obj = { a: 'hello' }
      expect { described_class.deep_freeze(obj) }.not_to raise_error
      expect(obj).to be_frozen
    end
  end

  describe '.deep_frozen?' do
    it 'returns true for deeply frozen objects' do
      obj = { a: { b: 'hello', c: [1, 'world'] } }
      described_class.deep_freeze(obj)

      expect(described_class.deep_frozen?(obj)).to be true
    end

    it 'returns false for shallow frozen objects' do
      obj = { a: { b: +'hello' } }
      obj.freeze

      expect(described_class.deep_frozen?(obj)).to be false
    end

    it 'returns true for primitives' do
      expect(described_class.deep_frozen?(42)).to be true
      expect(described_class.deep_frozen?(:sym)).to be true
      expect(described_class.deep_frozen?(true)).to be true
      expect(described_class.deep_frozen?(nil)).to be true
    end

    it 'handles circular references' do
      a = { name: 'a' }
      b = { name: 'b', ref: a }
      a[:ref] = b
      described_class.deep_freeze(a)

      expect(described_class.deep_frozen?(a)).to be true
    end
  end

  describe '.deep_dup' do
    it 'creates an unfrozen deep copy' do
      obj = { a: { b: 'hello', c: [1, 'world'] } }
      described_class.deep_freeze(obj)

      copy = described_class.deep_dup(obj)

      expect(copy).not_to be_frozen
      expect(copy[:a]).not_to be_frozen
      expect(copy[:a][:b]).not_to be_frozen
      expect(copy[:a][:c]).not_to be_frozen
      expect(copy).to eq({ a: { b: 'hello', c: [1, 'world'] } })
    end

    it 'creates independent copies' do
      obj = { a: [1, 2, 3] }
      copy = described_class.deep_dup(obj)

      copy[:a] << 4
      expect(obj[:a]).to eq([1, 2, 3])
    end

    it 'handles circular references' do
      a = { name: 'a' }
      b = { name: 'b', ref: a }
      a[:ref] = b
      described_class.deep_freeze(a)

      copy = described_class.deep_dup(a)
      expect(copy).not_to be_frozen
      expect(copy[:name]).to eq('a')
      expect(copy[:ref][:name]).to eq('b')
      expect(copy[:ref][:ref]).to equal(copy)
    end

    it 'preserves numeric and symbol values' do
      obj = { count: 42, name: :test, flag: true, empty: nil }
      copy = described_class.deep_dup(obj)

      expect(copy).to eq(obj)
    end
  end
end
