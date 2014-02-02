# frozen_string_literal: true

require 'set'
require_relative 'deep_freeze/version'

module Philiprehberger
  module DeepFreeze
    class Error < StandardError; end

    IMMUTABLE_TYPES = [NilClass, TrueClass, FalseClass, Integer, Float, Symbol].freeze

    # Recursively freeze an object graph
    #
    # @param obj [Object] the object to freeze
    # @param except [Array<Symbol>] hash keys to skip
    # @return [Object] the frozen object
    def self.freeze(obj, except: [], seen: nil)
      return obj if IMMUTABLE_TYPES.any? { |t| obj.is_a?(t) }

      seen ||= Set.new
      return obj if seen.include?(obj.object_id)

      seen.add(obj.object_id)

      case obj
      when Hash
        obj.each do |key, value|
          next if except.include?(key)

          self.freeze(value, except: except, seen: seen)
        end
        obj.freeze
      when Array
        obj.each { |item| self.freeze(item, except: except, seen: seen) }
        obj.freeze
      when Set
        obj.each { |item| self.freeze(item, except: except, seen: seen) }
        obj.freeze
      when String
        obj.freeze
      when Struct
        obj.each { |value| self.freeze(value, except: except, seen: seen) }
        obj.freeze
      else
        obj.freeze
      end

      obj
    end

    # Check if an object graph is deeply frozen
    #
    # @param obj [Object] the object to check
    # @return [Boolean] true if all nested objects are frozen
    def self.frozen?(obj, seen: nil)
      return true if IMMUTABLE_TYPES.any? { |t| obj.is_a?(t) }
      return false unless obj.frozen?

      seen ||= Set.new
      return true if seen.include?(obj.object_id)

      seen.add(obj.object_id)

      case obj
      when Hash
        obj.each_value.all? { |v| self.frozen?(v, seen: seen) }
      when Array, Set
        obj.all? { |item| self.frozen?(item, seen: seen) }
      when Struct
        obj.to_a.all? { |v| self.frozen?(v, seen: seen) }
      else
        true
      end
    end

    # Create a deep unfrozen copy of an object
    #
    # @param obj [Object] the object to duplicate
    # @return [Object] an unfrozen deep copy
    def self.dup(obj, seen: nil)
      return obj if IMMUTABLE_TYPES.any? { |t| obj.is_a?(t) }

      seen ||= {}
      return seen[obj.object_id] if seen.key?(obj.object_id)

      case obj
      when Hash
        copy = {}
        seen[obj.object_id] = copy
        obj.each { |k, v| copy[k] = self.dup(v, seen: seen) }
        copy
      when Array
        copy = []
        seen[obj.object_id] = copy
        obj.each { |item| copy << self.dup(item, seen: seen) }
        copy
      when String
        obj.dup
      else
        obj.dup
      end
    end
  end
end
