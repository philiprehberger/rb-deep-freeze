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
    end
  end
end
