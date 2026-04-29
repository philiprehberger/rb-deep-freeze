# frozen_string_literal: true

require 'set'
require_relative 'deep_freeze/version'

module Philiprehberger
  module DeepFreeze
    class << self
      # Recursively freeze an object and all nested objects it references. Descends
      # into Hash, Array, Set, Struct, and Data (Ruby 3.2+) graphs and freezes every
      # reachable value. Safe against circular references via a visited-set.
      #
      # @param obj [Object] object graph to freeze in place
      # @param except [Array<Symbol, Object>] Hash keys / Struct member names to leave unfrozen
      # @param seen [Set, nil] internal visited-set for circular reference detection
      # @return [Object] the same object (now frozen), or a new Data instance with frozen members
      def deep_freeze(obj, except: [], seen: nil)
        seen ||= Set.new
        return obj if obj.frozen? || seen.include?(obj.object_id)

        seen.add(obj.object_id)

        if defined?(Data) && obj.is_a?(Data)
          frozen_attrs = {}
          obj.class.members.each do |member|
            frozen_attrs[member] = deep_freeze(obj.send(member), except: except, seen: seen)
          end
          return obj.class.new(**frozen_attrs)
        end

        case obj
        when Hash
          obj.each do |key, value|
            next if except.include?(key)

            deep_freeze(key, except: except, seen: seen)
            deep_freeze(value, except: except, seen: seen)
          end
        when Array
          obj.each { |item| deep_freeze(item, except: except, seen: seen) }
        when Set
          obj.each { |item| deep_freeze(item, except: except, seen: seen) }
        when Struct
          obj.each_pair do |key, value|
            next if except.include?(key)

            deep_freeze(value, except: except, seen: seen)
          end
        when String
        end
        obj.freeze

        obj
      end

      # Freeze multiple object graphs with a shared visited-set so that
      # references shared across the objects are detected as circular.
      #
      # @param objects [Array<Object>] the object graphs to freeze
      # @param except [Array<Symbol, Object>] Hash keys / Struct member names to leave unfrozen
      # @return [Array<Object>] the input objects (each now deeply frozen)
      def deep_freeze_all(*objects, except: [])
        seen = Set.new
        objects.each { |obj| deep_freeze(obj, except: except, seen: seen) }
        objects
      end

      # Create a fully independent deep copy of the object, then deep-freeze it.
      # The original is never mutated.
      #
      # @param obj [Object] the source object graph
      # @param except [Array<Symbol, Object>] Hash keys / Struct member names to leave unfrozen in the copy
      # @return [Object] a deeply frozen copy
      def deep_clone(obj, except: [])
        copy = deep_dup(obj)
        deep_freeze(copy, except: except)
        copy
      end

      # Recursively freeze only the keys of every Hash reachable from the input,
      # leaving the values mutable. Descends through Arrays and Sets to find
      # nested Hashes.
      #
      # @param hash [Object] object graph whose Hash keys should be frozen
      # @param seen [Set, nil] internal visited-set for circular reference detection
      # @return [Object] the original object (with its Hash keys frozen in place)
      def freeze_hash_keys(hash, seen: nil)
        seen ||= Set.new
        return hash if seen.include?(hash.object_id)

        seen.add(hash.object_id)

        case hash
        when Hash
          hash.each do |key, value|
            deep_freeze_key(key, seen)
            freeze_hash_keys(value, seen: seen)
          end
        when Array
          hash.each { |item| freeze_hash_keys(item, seen: seen) }
        when Set
          hash.each { |item| freeze_hash_keys(item, seen: seen) }
        end

        hash
      end

      # Return whether the object and every nested value reachable from it is
      # frozen. Descends into Hash, Array, Set, Struct, and Data graphs, and
      # handles circular references via a visited-set.
      #
      # @param obj [Object] the object graph to check
      # @param except [Array<Symbol, Object>] Hash keys / Struct member names to ignore when testing frozen state
      # @param seen [Set, nil] internal visited-set for circular reference detection
      # @return [Boolean] true if obj and all nested values (outside `except`) are frozen
      def deep_frozen?(obj, except: [], seen: nil)
        seen ||= Set.new
        return true if seen.include?(obj.object_id)
        return false unless obj.frozen?

        seen.add(obj.object_id)

        if defined?(Data) && obj.is_a?(Data)
          return obj.class.members.all? { |m| deep_frozen?(obj.send(m), except: except, seen: seen) }
        end

        case obj
        when Hash
          obj.each do |key, value|
            next if except.include?(key)

            return false unless deep_frozen?(key, except: except, seen: seen)
            return false unless deep_frozen?(value, except: except, seen: seen)
          end
        when Array
          obj.each { |item| return false unless deep_frozen?(item, except: except, seen: seen) }
        when Set
          obj.each { |item| return false unless deep_frozen?(item, except: except, seen: seen) }
        when Struct
          obj.each_pair do |key, value|
            next if except.include?(key)

            return false unless deep_frozen?(value, except: except, seen: seen)
          end
        end

        true
      end

      # Recursively duplicate an object graph, producing a fully independent,
      # unfrozen copy. Descends into Hash, Array, Set, Struct, and Data. Returns
      # the original value for immutable primitives (Integer, Symbol, nil, true,
      # false, Range, Regexp) since duplicating them yields no benefit.
      #
      # @param obj [Object] the object graph to duplicate
      # @param seen [Hash, nil] internal original-to-copy map for circular reference detection
      # @return [Object] an independent unfrozen copy (or `obj` itself if immutable by design)
      def deep_dup(obj, seen: nil)
        seen ||= {}
        return seen[obj.object_id] if seen.key?(obj.object_id)

        if defined?(Data) && obj.is_a?(Data)
          duped_attrs = {}
          obj.class.members.each do |member|
            duped_attrs[member] = deep_dup(obj.send(member), seen: seen)
          end
          result = obj.class.new(**duped_attrs)
          seen[obj.object_id] = result
          return result
        end

        case obj
        when Hash
          copy = {}
          seen[obj.object_id] = copy
          obj.each do |key, value|
            copy[deep_dup(key, seen: seen)] = deep_dup(value, seen: seen)
          end
          copy
        when Array
          copy = []
          seen[obj.object_id] = copy
          obj.each { |item| copy << deep_dup(item, seen: seen) }
          copy
        when Set
          copy = Set.new
          seen[obj.object_id] = copy
          obj.each { |item| copy.add(deep_dup(item, seen: seen)) }
          copy
        when String
          copy = obj.dup
          seen[obj.object_id] = copy
          copy
        when Numeric, Symbol, TrueClass, FalseClass, NilClass
          obj
        when Range, Regexp
          obj
        else
          copy = obj.dup
          seen[obj.object_id] = copy
          copy
        end
      end

      # Recursively unfreeze an object graph. Returns an unfrozen copy for
      # frozen containers (produced via `dup`) and recurses into their children.
      # Immutable primitives (Integer, Symbol, nil, true, false, Range, Regexp)
      # are returned as-is.
      #
      # The `except:` option here has the *opposite* semantics of `deep_freeze`:
      # values at the listed Hash keys / Struct member names are left frozen.
      #
      # @param obj [Object] the object graph to thaw
      # @param except [Array<Symbol, Object>] Hash keys / Struct member names to leave frozen
      # @param seen [Hash, nil] internal original-to-copy map for circular reference detection
      # @return [Object] an unfrozen copy of the graph (or `obj` itself if already immutable)
      def deep_thaw(obj, except: [], seen: nil)
        seen ||= {}
        return seen[obj.object_id] if seen.key?(obj.object_id)

        case obj
        when Numeric, Symbol, TrueClass, FalseClass, NilClass, Range, Regexp
          return obj
        end

        if defined?(Data) && obj.is_a?(Data)
          thawed_attrs = {}
          obj.class.members.each do |member|
            thawed_attrs[member] = deep_thaw(obj.send(member), except: except, seen: seen)
          end
          result = obj.class.new(**thawed_attrs)
          seen[obj.object_id] = result
          return result
        end

        case obj
        when Hash
          copy = obj.frozen? ? obj.dup : obj
          seen[obj.object_id] = copy
          entries = obj.to_a
          copy.clear
          entries.each do |key, value|
            if except.include?(key)
              copy[key] = value
            else
              copy[deep_thaw(key, except: except, seen: seen)] = deep_thaw(value, except: except, seen: seen)
            end
          end
          copy
        when Array
          copy = obj.frozen? ? obj.dup : obj
          seen[obj.object_id] = copy
          obj.each_with_index do |item, i|
            copy[i] = deep_thaw(item, except: except, seen: seen)
          end
          copy
        when Set
          copy = obj.frozen? ? obj.dup : obj
          seen[obj.object_id] = copy
          thawed_items = obj.map { |item| deep_thaw(item, except: except, seen: seen) }
          copy.clear
          thawed_items.each { |item| copy.add(item) }
          copy
        when Struct
          copy = obj.frozen? ? obj.dup : obj
          seen[obj.object_id] = copy
          obj.each_pair do |key, value|
            copy[key] = if except.include?(key)
                          value
                        else
                          deep_thaw(value, except: except, seen: seen)
                        end
          end
          copy
        when String
          copy = obj.frozen? ? obj.dup : obj
          seen[obj.object_id] = copy
          copy
        else
          copy = obj.frozen? ? obj.dup : obj
          seen[obj.object_id] = copy
          copy
        end
      end

      # Deep structural equality check that descends into nested Hash, Array,
      # Set, Struct, and Data objects. Unlike `==`, this method compares
      # structural content rather than frozen-state or object identity, making
      # it safe to compare a deeply frozen graph against an unfrozen copy.
      #
      # @param a [Object] first object
      # @param b [Object] second object
      # @param path [Array] internal path accumulator for diff keys
      # @return [Hash] a hash mapping each differing path to `{ left:, right: }`; empty when the graphs are equal
      def deep_diff(a, b, path: [])
        return {} if a.equal?(b)

        unless a.instance_of?(b.class)
          return { path => { left: a, right: b } }
        end

        if defined?(Data) && a.is_a?(Data)
          return diff_members(a, b, a.class.members, path)
        end

        case a
        when Hash then diff_hashes(a, b, path)
        when Array then diff_arrays(a, b, path)
        when Struct then diff_members(a, b, a.members, path)
        else
          a == b ? {} : { path => { left: a, right: b } }
        end
      end

      # Recursively count every node in an object graph, including the root.
      # Hashes contribute 1 plus the count of every key and value; Arrays
      # contribute 1 plus the count of every element; Struct and Data instances
      # contribute 1 plus the count of every member value. All other values
      # (scalars, nil, etc.) count as 1. Safe against circular references via a
      # visited-set — already-visited nodes contribute 0.
      #
      # @param obj [Object] the object graph to count
      # @param seen [Set, nil] internal visited-set for circular reference detection
      # @return [Integer] the total number of nodes reachable from `obj`
      def deep_count(obj, seen: nil)
        seen ||= Set.new
        return 0 unless seen.add?(obj.object_id)

        if defined?(Data) && obj.is_a?(Data)
          return 1 + obj.class.members.sum { |m| deep_count(obj.send(m), seen: seen) }
        end

        case obj
        when Hash
          1 + obj.sum { |k, v| deep_count(k, seen: seen) + deep_count(v, seen: seen) }
        when Array
          1 + obj.sum { |item| deep_count(item, seen: seen) }
        when Struct
          1 + obj.each_pair.sum { |_key, value| deep_count(value, seen: seen) }
        else
          1
        end
      end

      # Deeply merge two hashes, recursing into nested hashes. When both values
      # for a key are hashes, merges them recursively. Otherwise b's value wins
      # (unless a block is given, which resolves conflicts). Returns a new
      # deeply frozen hash.
      #
      # @param a [Hash] the base hash
      # @param b [Hash] the overriding hash
      # @yield [key, a_val, b_val] conflict resolver; only invoked for leaf conflicts
      # @yieldreturn [Object] the merged value for `key`
      # @return [Hash] a new frozen hash with `a` and `b` deeply merged
      def deep_merge(a, b, &block)
        result = a.each_with_object({}) do |(key, a_val), merged|
          if b.key?(key)
            b_val = b[key]
            merged[key] = if a_val.is_a?(Hash) && b_val.is_a?(Hash)
                            deep_merge(a_val, b_val, &block)
                          elsif block
                            yield(key, a_val, b_val)
                          else
                            b_val
                          end
          else
            merged[key] = a_val
          end
        end

        b.each do |key, b_val|
          result[key] = b_val unless result.key?(key)
        end

        deep_freeze(deep_dup(result))
      end

      # Structural equality across nested Hash, Array, Set, Struct, and Data
      # graphs — ignores frozen state and object identity.
      #
      # @param a [Object] first object
      # @param b [Object] second object
      # @return [Boolean] true if the two graphs are structurally equal
      def deep_equal?(a, b)
        return true if a.equal?(b)
        return false unless a.instance_of?(b.class)

        if defined?(Data) && a.is_a?(Data)
          return a.class.members.all? { |m| deep_equal?(a.send(m), b.send(m)) }
        end

        case a
        when Hash
          return false unless a.size == b.size

          a.all? { |k, v| b.key?(k) && deep_equal?(v, b[k]) }
        when Array
          return false unless a.size == b.size

          a.each_with_index.all? { |item, i| deep_equal?(item, b[i]) }
        when Set
          return false unless a.size == b.size

          a.all? { |item| b.any? { |other| deep_equal?(item, other) } }
        when Struct
          a.each_pair.all? { |key, value| deep_equal?(value, b[key]) }
        else
          a == b
        end
      end

      private

      def deep_freeze_key(key, seen)
        return key if key.frozen? || seen.include?(key.object_id)

        seen.add(key.object_id)

        case key
        when Hash
          key.each do |k, v|
            deep_freeze_key(k, seen)
            deep_freeze_key(v, seen)
          end
        when Array
          key.each { |item| deep_freeze_key(item, seen) }
        when Set
          key.each { |item| deep_freeze_key(item, seen) }
        end
        key.freeze
      end

      def diff_hashes(a, b, path)
        result = {}
        (a.keys | b.keys).each do |key|
          sub = path + [key]
          if !a.key?(key)
            result[sub] = { left: nil, right: b[key] }
          elsif !b.key?(key)
            result[sub] = { left: a[key], right: nil }
          else
            result.merge!(deep_diff(a[key], b[key], path: sub))
          end
        end
        result
      end

      def diff_arrays(a, b, path)
        result = {}
        max = [a.size, b.size].max
        max.times do |i|
          sub = path + [i]
          if i >= a.size
            result[sub] = { left: nil, right: b[i] }
          elsif i >= b.size
            result[sub] = { left: a[i], right: nil }
          else
            result.merge!(deep_diff(a[i], b[i], path: sub))
          end
        end
        result
      end

      def diff_members(a, b, members, path)
        result = {}
        members.each do |m|
          result.merge!(deep_diff(a.send(m), b.send(m), path: path + [m]))
        end
        result
      end
    end
  end
end
