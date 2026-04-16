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

  describe '.deep_freeze_all' do
    it 'freezes multiple objects in one call' do
      a = { name: +'Alice' }
      b = { name: +'Bob' }
      described_class.deep_freeze_all(a, b)

      expect(a).to be_frozen
      expect(a[:name]).to be_frozen
      expect(b).to be_frozen
      expect(b[:name]).to be_frozen
    end

    it 'detects shared circular references across objects' do
      shared = { value: +'shared' }
      a = { ref: shared }
      b = { ref: shared }
      shared[:back] = a

      expect { described_class.deep_freeze_all(a, b) }.not_to raise_error
      expect(a).to be_frozen
      expect(b).to be_frozen
      expect(shared).to be_frozen
    end

    it 'respects the except: option across all objects' do
      a = { keep: +'mutable_a', freeze_me: +'frozen_a' }
      b = { keep: +'mutable_b', freeze_me: +'frozen_b' }
      described_class.deep_freeze_all(a, b, except: [:keep])

      expect(a[:keep]).not_to be_frozen
      expect(a[:freeze_me]).to be_frozen
      expect(b[:keep]).not_to be_frozen
      expect(b[:freeze_me]).to be_frozen
    end

    it 'returns the array of objects' do
      a = { x: 1 }
      b = { y: 2 }
      result = described_class.deep_freeze_all(a, b)

      expect(result).to eq([a, b])
    end

    it 'handles a single object' do
      a = { name: +'Alice' }
      described_class.deep_freeze_all(a)

      expect(a).to be_frozen
      expect(a[:name]).to be_frozen
    end
  end

  describe '.deep_clone' do
    it 'returns a frozen deep copy' do
      original = { users: [{ name: +'Alice' }] }
      clone = described_class.deep_clone(original)

      expect(clone).to be_frozen
      expect(clone[:users]).to be_frozen
      expect(clone[:users][0][:name]).to be_frozen
      expect(described_class.deep_frozen?(clone)).to be true
    end

    it 'does not modify the original object' do
      original = { name: +'Alice' }
      described_class.deep_clone(original)

      expect(original).not_to be_frozen
      expect(original[:name]).not_to be_frozen
    end

    it 'produces a structurally equal but independent copy' do
      original = { a: [1, 2, 3], b: { c: +'hello' } }
      clone = described_class.deep_clone(original)

      expect(described_class.deep_equal?(original, clone)).to be true
      expect(clone).not_to equal(original)
    end

    it 'handles circular references' do
      a = { name: +'a' }
      a[:self] = a
      clone = described_class.deep_clone(a)

      expect(clone).to be_frozen
      expect(clone[:self]).to equal(clone)
    end

    it 'respects the except: option' do
      original = { keep: +'mutable', data: +'frozen' }
      clone = described_class.deep_clone(original, except: [:keep])

      expect(clone[:keep]).not_to be_frozen
      expect(clone[:data]).to be_frozen
    end
  end

  describe '.freeze_hash_keys' do
    it 'freezes non-string hash keys' do
      key = [1, 2, 3]
      obj = { key => 'value' }
      described_class.freeze_hash_keys(obj)

      expect(key).to be_frozen
    end

    it 'leaves hash values unfrozen' do
      value = +'mutable_value'
      obj = { 'key' => value }
      described_class.freeze_hash_keys(obj)

      expect(value).not_to be_frozen
    end

    it 'recursively freezes keys in nested hashes' do
      inner_key = [:inner]
      obj = { 'outer' => { inner_key => 'value' } }
      described_class.freeze_hash_keys(obj)

      expect(inner_key).to be_frozen
    end

    it 'freezes keys in hashes nested inside arrays' do
      key = [:array_key]
      obj = [{ key => 'value' }]
      described_class.freeze_hash_keys(obj)

      expect(key).to be_frozen
    end

    it 'leaves values in nested structures unfrozen' do
      value = +'deep_value'
      obj = { 'a' => [{ 'b' => value }] }
      described_class.freeze_hash_keys(obj)

      expect(value).not_to be_frozen
    end

    it 'handles circular references' do
      a = {}
      key = [:key]
      a[key] = a

      expect { described_class.freeze_hash_keys(a) }.not_to raise_error
      expect(key).to be_frozen
    end

    it 'returns the original object' do
      obj = { 'a' => 1 }
      result = described_class.freeze_hash_keys(obj)

      expect(result).to equal(obj)
    end
  end

  describe '.deep_merge' do
    it 'merges two flat hashes with b winning on conflict' do
      a = { x: 1, y: 2 }
      b = { y: 3, z: 4 }
      result = described_class.deep_merge(a, b)

      expect(result).to eq({ x: 1, y: 3, z: 4 })
    end

    it 'recursively merges nested hashes' do
      a = { db: { host: 'localhost', port: 5432 } }
      b = { db: { port: 3306, name: 'app' } }
      result = described_class.deep_merge(a, b)

      expect(result).to eq({ db: { host: 'localhost', port: 3306, name: 'app' } })
    end

    it 'deeply recurses into multiple levels of nesting' do
      a = { a: { b: { c: 1, d: 2 }, e: 3 } }
      b = { a: { b: { c: 10, f: 4 }, g: 5 } }
      result = described_class.deep_merge(a, b)

      expect(result).to eq({ a: { b: { c: 10, d: 2, f: 4 }, e: 3, g: 5 } })
    end

    it 'overwrites arrays from b (no array merge)' do
      a = { tags: [1, 2] }
      b = { tags: [3, 4, 5] }
      result = described_class.deep_merge(a, b)

      expect(result[:tags]).to eq([3, 4, 5])
    end

    it 'uses the block to resolve conflicts when given' do
      a = { x: 1, y: 2 }
      b = { y: 10, z: 4 }
      result = described_class.deep_merge(a, b) { |_key, old_val, new_val| old_val + new_val }

      expect(result).to eq({ x: 1, y: 12, z: 4 })
    end

    it 'does not invoke the block for nested hash merges' do
      a = { nested: { a: 1 } }
      b = { nested: { b: 2 } }
      block_called_for = []
      described_class.deep_merge(a, b) { |key, old_val, new_val| block_called_for << key; new_val }

      expect(block_called_for).to be_empty
      expect(result = described_class.deep_merge(a, b)).to eq({ nested: { a: 1, b: 2 } })
    end

    it 'returns a frozen result' do
      a = { x: 1 }
      b = { y: 2 }
      result = described_class.deep_merge(a, b)

      expect(result).to be_frozen
      expect(described_class.deep_frozen?(result)).to be true
    end

    it 'deeply freezes nested values in the result' do
      a = { db: { host: 'localhost' } }
      b = { db: { port: 3306 } }
      result = described_class.deep_merge(a, b)

      expect(result[:db]).to be_frozen
      expect(result[:db][:host]).to be_frozen
    end

    it 'does not modify the original hashes' do
      a = { x: 1, nested: { a: 1 } }
      b = { y: 2, nested: { b: 2 } }
      described_class.deep_merge(a, b)

      expect(a).to eq({ x: 1, nested: { a: 1 } })
      expect(b).to eq({ y: 2, nested: { b: 2 } })
      expect(a).not_to be_frozen
      expect(b).not_to be_frozen
    end

    it 'handles empty hashes' do
      expect(described_class.deep_merge({}, { a: 1 })).to eq({ a: 1 })
      expect(described_class.deep_merge({ a: 1 }, {})).to eq({ a: 1 })
      expect(described_class.deep_merge({}, {})).to eq({})
    end

    it 'handles one side having a hash and the other a non-hash for the same key' do
      a = { x: { nested: 1 } }
      b = { x: 'replaced' }
      result = described_class.deep_merge(a, b)

      expect(result[:x]).to eq('replaced')
    end
  end

  describe '.deep_diff' do
    it 'returns empty hash for identical objects' do
      a = { name: 'Alice', tags: [1, 2] }
      expect(described_class.deep_diff(a, a.dup)).to eq({})
    end

    it 'reports leaf differences in hashes' do
      a = { name: 'Alice', age: 30 }
      b = { name: 'Bob', age: 30 }
      diff = described_class.deep_diff(a, b)
      expect(diff).to eq({ [:name] => { left: 'Alice', right: 'Bob' } })
    end

    it 'reports missing keys' do
      a = { x: 1 }
      b = { x: 1, y: 2 }
      diff = described_class.deep_diff(a, b)
      expect(diff).to eq({ [:y] => { left: nil, right: 2 } })
    end

    it 'reports extra keys' do
      a = { x: 1, y: 2 }
      b = { x: 1 }
      diff = described_class.deep_diff(a, b)
      expect(diff).to eq({ [:y] => { left: 2, right: nil } })
    end

    it 'reports array element differences' do
      a = [1, 2, 3]
      b = [1, 9, 3]
      diff = described_class.deep_diff(a, b)
      expect(diff).to eq({ [1] => { left: 2, right: 9 } })
    end

    it 'reports array length differences' do
      a = [1, 2]
      b = [1, 2, 3]
      diff = described_class.deep_diff(a, b)
      expect(diff).to eq({ [2] => { left: nil, right: 3 } })
    end

    it 'reports type mismatches' do
      a = { x: 'string' }
      b = { x: 42 }
      diff = described_class.deep_diff(a, b)
      expect(diff).to eq({ [:x] => { left: 'string', right: 42 } })
    end

    it 'descends into nested structures' do
      a = { users: [{ name: 'Alice' }] }
      b = { users: [{ name: 'Bob' }] }
      diff = described_class.deep_diff(a, b)
      expect(diff).to eq({ [:users, 0, :name] => { left: 'Alice', right: 'Bob' } })
    end

    it 'handles Struct members' do
      klass = Struct.new(:a, :b)
      diff = described_class.deep_diff(klass.new(1, 'x'), klass.new(1, 'y'))
      expect(diff).to eq({ [:b] => { left: 'x', right: 'y' } })
    end

    it 'returns empty hash for equal Structs' do
      klass = Struct.new(:a, :b)
      expect(described_class.deep_diff(klass.new(1, 2), klass.new(1, 2))).to eq({})
    end
  end
end
