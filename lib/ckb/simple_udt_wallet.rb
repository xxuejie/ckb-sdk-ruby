# frozen_string_literal: true

module CKB
  UDT_SCRIPT_HASH = "0x57dd0067814dab356e05c6def0d094bb79776711e68ffdfad2df6a7f877f7db6"

  class SimpleUdtWallet
    attr_reader :api, :key, :hash_type, :owner_script_hash, :cell_dep

    def initialize(api, key, owner_script_hash, hash_type: "type")
      @api = api
      @key = key
      @owner_script_hash = owner_script_hash
      @hash_type = hash_type

      # Scanning for cell dep
      to = api.get_tip_block_number.to_i
      current_from = 0
      while current_from <= to && (!@cell_dep)
        block = api.get_block_by_number(current_from)
        block.transactions.each do |tx|
          tx.outputs_data.each_with_index.each do |data, i|
            if CKB::Blake2b.hexdigest(CKB::Utils.hex_to_bin(data)) == UDT_SCRIPT_HASH
              @cell_dep = CKB::Types::CellDep.new(dep_type: "code", out_point: CKB::Types::OutPoint.new(tx_hash: tx.hash, index: i))
            end
          end
        end
        current_from += 1
      end

      unless @cell_dep
        raise "UDT Script is not deployed!"
      end
    end

    def send_amount(target_address, amount, fee: 0, use_dep_group: true)
      parsed_address = AddressParser.new(target_address).parse
      raise "Right now only supports sending to default single signed lock!" if parsed_address.address_type == "SHORTMULTISIG"

      send_amount_raw(parsed_address.script, amount, fee: fee, use_dep_group: use_dep_group)
    end

    def send_amount_raw(target_lock, amount, fee: 0, use_dep_group: true)
      unspent_cells = get_unspent_cells
      raise "Amount not enough" if amount > unspent_cells[:total_amounts]
      raise "Capacity not enough" if unspent_cells[:total_capacities] < CKB::Utils.byte_to_shannon(142 * 2) + fee

      tx = Types::Transaction.new(
        version: 0,
        cell_deps: [cell_dep.dup],
        inputs: unspent_cells[:cells].map do |cell|
          Types::Input.new(
            previous_output: cell[:cell].out_point,
            since: 0
          )
        end,
        outputs: [
          Types::Output.new(
            capacity: CKB::Utils.byte_to_shannon(142),
            lock: target_lock,
            type: type
          ),
          Types::Output.new(
            capacity: unspent_cells[:total_capacities] - CKB::Utils.byte_to_shannon(142) - fee,
            lock: lock,
            type: type
          )
        ],
        outputs_data: [
          pack_amount(amount),
          pack_amount(unspent_cells[:total_amounts] - amount)
        ],
        witnesses: unspent_cells[:cells].length.times.map do
          Types::Witness.new
        end
      )
      if use_dep_group
        tx.cell_deps << Types::CellDep.new(out_point: api.secp_group_out_point, dep_type: "dep_group")
      else
        tx.cell_deps << Types::CellDep.new(out_point: api.secp_code_out_point, dep_type: "code")
        tx.cell_deps << Types::CellDep.new(out_point: api.secp_data_out_point, dep_type: "code")
      end

      tx = tx.sign(key)

      api.send_transaction(tx)
    end

    def create_empty_wallet(capacity, fee: 0)
      deposit_capacity_to_udt_wallet(capacity, fee: fee)
    end

    def deposit_capacity_to_udt_wallet(capacity, fee: 0)
      tx = wallet.generate_tx(wallet.address, capacity, pack_amount(0), fee: fee)
      tx.cell_deps << cell_dep.dup
      tx.outputs[0].type = type
      tx = tx.sign(key)

      api.send_transaction(tx)
    end

    def balance
      get_unspent_cells[:total_amounts]
    end

    def capacities
      get_unspent_cells[:total_capacities]
    end

    def get_unspent_cells
      to = api.get_tip_block_number.to_i
      results = []
      total_capacities = 0
      total_amounts = 0
      current_from = 0
      while current_from <= to
        current_to = [current_from + 100, to].min
        cells = api.get_cells_by_lock_hash(lock_hash, current_from, current_to)
        cells.each do |cell|
          if cell.type && cell.type.compute_hash == type_hash
            live_cell = api.get_live_cell(cell.out_point, true)
            output_data = live_cell.cell.data.content
            amount = unpack_amount(output_data)
            results << {
              cell: cell,
              amount: amount
            }
            total_capacities += cell.capacity
            total_amounts += amount
          end
        end
        current_from = current_to + 1
      end
      {
        cells: results,
        total_capacities: total_capacities,
        total_amounts: total_amounts
      }
    end

    def pack_amount(amount)
      values = [amount & 0xFFFFFFFFFFFFFFFF, (amount >> 64) & 0xFFFFFFFFFFFFFFFF]
      CKB::Utils.bin_to_hex(values.pack("Q<Q<"))
    end

    def unpack_amount(data)
      values = CKB::Utils.hex_to_bin(data).unpack("Q<Q<")
      (values[1] << 64) | values[0]
    end

    def type
      Types::Script.new(
        code_hash: UDT_SCRIPT_HASH,
        args: owner_script_hash,
        hash_type: "data"
      )
    end

    def type_hash
      type.compute_hash
    end

    def wallet
      CKB::Wallet.new(api, key, hash_type: hash_type, skip_data_and_type: true)
    end

    def lock
      wallet.lock
    end

    def lock_hash
      wallet.lock_hash
    end

    def address
      wallet.address
    end
  end
end
