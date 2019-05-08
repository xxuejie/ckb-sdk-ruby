# frozen_string_literal: true

module CKB
  module Types
    class OutPoint
      attr_reader :tx_hash, :index

      # @param tx_hash [String] 0x...
      # @param index [Integer] 0x...
      def initialize(tx_hash:, index:)
        @tx_hash = tx_hash
        @index = index
      end

      def to_h
        {
          cell: {
            tx_hash: @tx_hash,
            index: @index
          }
        }
      end

      def self.from_h(hash)
        new(
          tx_hash: (hash[:cell] || {})[:tx_hash],
          index: (hash[:cell] || {})[:index]
        )
      end
    end
  end
end
