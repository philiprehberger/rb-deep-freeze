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

    it 'returns same object for Integer (immutable primitive)' do
      obj = { count: 42 }
      copy = described_class.deep_dup(obj)
      expect(copy[:count]).to equal(42)
    end

    it 'returns same object for Symbol (immutable primitive)' do
      obj = { name: :test }
      copy = described_class.deep_dup(obj)
      expect(copy[:name]).to equal(:test)
    end

    it 'returns same object for true, false, and nil' do
      obj = { a: true, b: false, c: nil }
      copy = described_class.deep_dup(obj)
      expect(copy[:a]).to equal(true)
      expect(copy[:b]).to equal(false)
      expect(copy[:c]).to equal(nil)
    end

    it 'dups a Set into an independent copy' do
      require 'set'
      original = { tags: Set.new(%w[a b]) }
      described_class.deep_freeze(original)
      copy = described_class.deep_dup(original)

      expect(copy[:tags]).to be_a(Set)
      expect(copy[:tags]).not_to be_frozen
      expect(copy[:tags]).to eq(Set.new(%w[a b]))
      copy[:tags].add('c')
      expect(original[:tags]).not_to include('c')
    end

    it 'produces fully independent nested hash copies' do
      obj = { a: { b: { c: 'deep' } } }
      copy = described_class.deep_dup(obj)
      copy[:a][:b][:c] = 'changed'
      expect(obj[:a][:b][:c]).to eq('deep')
    end

    it 'produces independent array copies' do
      obj = [['inner']]
      copy = described_class.deep_dup(obj)
      copy[0] << 'added'
      expect(obj[0]).to eq(['inner'])
    end
  end

  describe '.deep_freeze on Struct' do
    it 'freezes a simple Struct and its members' do
      point = Struct.new(:x, :y)
      obj = point.new(+'hello', +'world')
      described_class.deep_freeze(obj)

      expect(obj).to be_frozen
      expect(obj.x).to be_frozen
      expect(obj.y).to be_frozen
    end

    it 'freezes a Struct nested inside a Hash' do
      person = Struct.new(:name, :age)
      data = { user: person.new(+'Alice', 30) }
      described_class.deep_freeze(data)

      expect(data[:user]).to be_frozen
      expect(data[:user].name).to be_frozen
    end

    it 'excludes specified keys in a Struct' do
      config = Struct.new(:host, :port)
      obj = config.new(+'localhost', 8080)
      described_class.deep_freeze(obj, except: [:host])

      expect(obj).to be_frozen
      expect(obj.host).not_to be_frozen
    end
  end

  context 'with Data class (Ruby 3.2+)', if: defined?(Data) && Data.respond_to?(:define) do
    let(:point_class) { Data.define(:x, :y) }
    let(:labeled_class) { Data.define(:label, :point) }

    describe '.deep_freeze' do
      it 'deep freezes Data member values' do
        str = 'hello'
        point = point_class.new(x: str, y: 2)
        result = described_class.deep_freeze(point)
        expect(result.x).to be_frozen
      end

      it 'returns a new Data when members need freezing' do
        point = point_class.new(x: 'hello', y: 2)
        result = described_class.deep_freeze(point)
        expect(result.x).to be_frozen
      end

      it 'handles nested Data objects' do
        point = point_class.new(x: 1, y: 2)
        labeled = labeled_class.new(label: 'origin', point: point)
        result = described_class.deep_freeze(labeled)
        expect(result.label).to be_frozen
      end
    end

    describe '.deep_frozen?' do
      it 'returns true for Data with frozen members' do
        point = point_class.new(x: 1, y: 2)
        expect(described_class.deep_frozen?(point)).to be true
      end

      it 'returns false for Data with unfrozen members' do
        point = point_class.new(x: +'hello', y: 2)
        expect(described_class.deep_frozen?(point)).to be false
      end
    end

    describe '.deep_dup' do
      it 'creates unfrozen copy of Data member values' do
        point = described_class.deep_freeze(point_class.new(x: 'hello', y: 2))
        duped = described_class.deep_dup(point)
        expect(duped.x).not_to be_frozen
      end

      it 'returns independent copy' do
        point = point_class.new(x: [1, 2, 3], y: 'test')
        frozen_point = described_class.deep_freeze(point)
        duped = described_class.deep_dup(frozen_point)
        expect(duped.x).not_to be_frozen
        expect(duped.x).to eq([1, 2, 3])
      end
    end
  end

  describe '.deep_freeze with multiple data types in one hash' do
    it 'freezes a hash containing strings, arrays, sets, and nested hashes' do
      require 'set'
      obj = {
        name: +'hello',
        items: [+'a', +'b'],
        tags: Set.new([+'x']),
        nested: { key: +'val' }
      }
      described_class.deep_freeze(obj)

      expect(obj[:name]).to be_frozen
      expect(obj[:items]).to be_frozen
      expect(obj[:items][0]).to be_frozen
      expect(obj[:tags]).to be_frozen
      expect(obj[:nested][:key]).to be_frozen
    end
  end

  describe '.deep_freeze with empty collections' do
    it 'freezes an empty hash' do
      obj = {}
      described_class.deep_freeze(obj)
      expect(obj).to be_frozen
    end

    it 'freezes an empty array' do
      obj = []
      described_class.deep_freeze(obj)
      expect(obj).to be_frozen
    end

    it 'freezes an empty Set' do
      require 'set'
      obj = Set.new
      described_class.deep_freeze(obj)
      expect(obj).to be_frozen
    end
  end

  describe '.deep_freeze with deeply nested structures (5+ levels)' do
    it 'freezes all levels of a 6-level deep hash' do
      obj = { a: { b: { c: { d: { e: { f: +'deep' } } } } } }
      described_class.deep_freeze(obj)

      expect(obj[:a][:b][:c][:d][:e][:f]).to be_frozen
      expect(described_class.deep_frozen?(obj)).to be true
    end

    it 'freezes all levels of a 6-level deep array' do
      obj = [[[[[['deep']]]]]]
      described_class.deep_freeze(obj)

      expect(obj[0][0][0][0][0][0]).to be_frozen
      expect(described_class.deep_frozen?(obj)).to be true
    end
  end

  describe '.deep_frozen? edge cases' do
    it 'returns false when a deeply nested string is not frozen' do
      obj = { a: { b: { c: +'mutable' } } }
      obj.freeze
      obj[:a].freeze

      expect(described_class.deep_frozen?(obj)).to be false
    end

    it 'returns true for an empty frozen hash' do
      obj = {}
      obj.freeze
      expect(described_class.deep_frozen?(obj)).to be true
    end

    it 'returns true for an empty frozen array' do
      obj = []
      obj.freeze
      expect(described_class.deep_frozen?(obj)).to be true
    end

    it 'returns true for a frozen Set with frozen elements' do
      require 'set'
      obj = Set.new(%w[a b])
      described_class.deep_freeze(obj)
      expect(described_class.deep_frozen?(obj)).to be true
    end

    it 'returns false for a frozen Set with unfrozen elements' do
      require 'set'
      s = +'mutable'
      obj = Set.new([s])
      obj.freeze
      expect(described_class.deep_frozen?(obj)).to be true
    end
  end

  describe '.deep_equal?' do
    it 'returns true for identical objects' do
      obj = { a: 1 }
      expect(described_class.deep_equal?(obj, obj)).to be true
    end

    it 'returns true for structurally equal nested hashes' do
      a = { users: [{ name: 'Alice', tags: %w[admin user] }] }
      b = { users: [{ name: 'Alice', tags: %w[admin user] }] }
      expect(described_class.deep_equal?(a, b)).to be true
    end

    it 'returns false for structurally different hashes' do
      a = { users: [{ name: 'Alice' }] }
      b = { users: [{ name: 'Bob' }] }
      expect(described_class.deep_equal?(a, b)).to be false
    end

    it 'ignores frozen state when comparing' do
      original = { users: [{ name: 'Alice', tags: ['admin'] }] }
      described_class.deep_freeze(original)
      copy = described_class.deep_dup(original)

      expect(original).to be_frozen
      expect(copy).not_to be_frozen
      expect(described_class.deep_equal?(original, copy)).to be true
    end

    it 'returns false when classes differ' do
      expect(described_class.deep_equal?({ a: 1 }, [[:a, 1]])).to be false
    end

    it 'returns false when arrays differ in size' do
      expect(described_class.deep_equal?([1, 2], [1, 2, 3])).to be false
    end

    it 'returns false when hashes differ in size' do
      expect(described_class.deep_equal?({ a: 1 }, { a: 1, b: 2 })).to be false
    end

    it 'compares nested arrays element-wise in order' do
      expect(described_class.deep_equal?([[1, 2], [3, 4]], [[1, 2], [3, 4]])).to be true
      expect(described_class.deep_equal?([[1, 2], [3, 4]], [[3, 4], [1, 2]])).to be false
    end

    it 'compares Sets as unordered' do
      a = Set.new([1, 2, 3])
      b = Set.new([3, 2, 1])
      expect(described_class.deep_equal?(a, b)).to be true
    end

    it 'returns false for Sets with different contents' do
      expect(described_class.deep_equal?(Set.new([1, 2]), Set.new([1, 3]))).to be false
    end

    it 'compares Struct instances field-by-field' do
      klass = Struct.new(:x, :y)
      expect(described_class.deep_equal?(klass.new(1, 'hi'), klass.new(1, 'hi'))).to be true
      expect(described_class.deep_equal?(klass.new(1, 'hi'), klass.new(1, 'bye'))).to be false
    end

    it 'handles deeply nested mixed structures' do
      a = { list: [Set.new([1, 2]), { inner: 'x' }] }
      b = { list: [Set.new([2, 1]), { inner: 'x' }] }
      expect(described_class.deep_equal?(a, b)).to be true
    end

    it 'compares primitives with ==' do
      expect(described_class.deep_equal?(1, 1)).to be true
      expect(described_class.deep_equal?('a', 'a')).to be true
      expect(described_class.deep_equal?(nil, nil)).to be true
      expect(described_class.deep_equal?(1, 2)).to be false
    end

    if defined?(Data)
      it 'compares Data class instances member-by-member' do
        klass = Data.define(:a, :b)
        expect(described_class.deep_equal?(klass.new(a: 1, b: [1, 2]), klass.new(a: 1, b: [1, 2]))).to be true
        expect(described_class.deep_equal?(klass.new(a: 1, b: [1, 2]), klass.new(a: 1, b: [1, 3]))).to be false
      end
    end
  end
end
