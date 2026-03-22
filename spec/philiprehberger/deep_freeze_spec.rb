# frozen_string_literal: true

RSpec.describe Philiprehberger::DeepFreeze do
  describe '.freeze' do
    it 'freezes nested hashes' do
      data = { a: { b: 'hello' } }
      result = described_class.freeze(data)
      expect(result[:a][:b]).to be_frozen
    end

    it 'freezes nested arrays' do
      data = { list: ['a', 'b'] }
      result = described_class.freeze(data)
      expect(result[:list][0]).to be_frozen
    end

    it 'handles circular references' do
      a = {}
      a[:self] = a
      expect { described_class.freeze(a) }.not_to raise_error
    end

    it 'excludes specified keys' do
      data = { keep: 'mutable', freeze_me: 'frozen' }
      result = described_class.freeze(data, except: [:keep])
      expect(result[:keep]).not_to be_frozen
      expect(result[:freeze_me]).to be_frozen
    end
  end

  describe '.frozen?' do
    it 'returns true for deeply frozen objects' do
      data = described_class.freeze({ a: { b: 'c' } })
      expect(described_class.frozen?(data)).to be true
    end

    it 'returns false for shallowly frozen objects' do
      data = { a: { b: 'c' } }
      data.freeze
      expect(described_class.frozen?(data)).to be false
    end
  end

  describe '.dup' do
    it 'creates unfrozen deep copy' do
      frozen = described_class.freeze({ a: { b: 'c' } })
      thawed = described_class.dup(frozen)
      expect(thawed[:a][:b]).not_to be_frozen
    end
  end
end
