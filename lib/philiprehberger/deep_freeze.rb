# frozen_string_literal: true

require 'set'
require_relative 'deep_freeze/version'

module Philiprehberger
  module DeepFreeze
    class << self
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

      def deep_frozen?(obj, seen: nil)
        seen ||= Set.new
        return true if seen.include?(obj.object_id)
        return false unless obj.frozen?

        seen.add(obj.object_id)

        if defined?(Data) && obj.is_a?(Data)
          return obj.class.members.all? { |m| deep_frozen?(obj.send(m), seen: seen) }
        end

        case obj
        when Hash
          obj.each do |key, value|
            return false unless deep_frozen?(key, seen: seen)
            return false unless deep_frozen?(value, seen: seen)
          end
        when Array
          obj.each { |item| return false unless deep_frozen?(item, seen: seen) }
        when Set
          obj.each { |item| return false unless deep_frozen?(item, seen: seen) }
        when Struct
          obj.each_pair { |_key, value| return false unless deep_frozen?(value, seen: seen) }
        end

        true
      end

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
        else
          copy = obj.dup
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
      # @return [Boolean] true if the two graphs are structurally equal
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
