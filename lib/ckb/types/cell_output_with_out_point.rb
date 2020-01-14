# frozen_string_literal: true

module CKB
  module Types
    class CellOutputWithOutPoint
      attr_accessor :lock, :out_point, :block_hash, :type
      attr_reader :capacity

      # @param capacity [String | Integer] integer or hex number
      # @param lock [CKB::Types::Script]
      # @param out_point [CKB::Types::OutPoint]
      # @param block_hash [String]
      def initialize(capacity:, lock:, out_point:, block_hash:, type: nil)
        @capacity = Utils.to_int(capacity)
        @lock = lock
        @out_point = out_point
        @block_hash = block_hash
        @type = type
      end

      def capacity=(value)
        @capacity = Utils.to_int(value)
      end

      def to_h
        h = {
          capacity: Utils.to_hex(@capacity),
          lock: @lock.to_h,
          block_hash: @block_hash,
          out_point: @out_point.to_h
        }
        h[:type] = @type.to_h if @type
        h
      end

      def self.from_h(hash)
        return if hash.nil?

        c = new(
          capacity: hash[:capacity],
          lock: Script.from_h(hash[:lock]),
          type: Script.from_h(hash[:type]),
          out_point: OutPoint.from_h(hash[:out_point]),
          block_hash: hash[:block_hash]
        )
      end
    end
  end
end
