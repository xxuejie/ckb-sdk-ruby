# frozen_string_literal: true

RSpec.describe CKB::API do
  Types = CKB::Types

  before do
    skip "not test rpc" if ENV["SKIP_RPC_TESTS"]
  end

  let(:api) { CKB::API.new }
  let(:lock_hash) { "0xe94e4b509d5946c54ea9bc7500af12fd35eebe0d47a6b3e502127f94d34997ac" }
  let(:block_h) do
    { uncles: [],
      proposals: [],
      transactions: [{ version: "0x0",
                       cell_deps: [],
                       header_deps: [],
                       inputs: [{ previous_output: { tx_hash: "0x0000000000000000000000000000000000000000000000000000000000000000", index: "0xffffffff" },
                                  since: "0x1" }],
                       outputs: [{ capacity: "0x2ca7071b9e",
                                   lock: { code_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
                                           args: "0x",
                                           hash_type: "type" },
                                   type: nil }],
                       outputs_data: ["0x"],
                       witnesses: ["0x490000001000000030000000310000009bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce801140000003954acece65096bfa81258983ddb83915fc56bd8"],
                       hash: "0x249ba6cc038ccb16a18b1da03b994f87a6e32bf128b553a66a5805e9d6f36c50" }],
      header: { difficulty: "0x100",
                hash: "0x358df0eb01609fe8631a8d666ab4fd3ffac4025b46f2fbafeb92783181e6ea80",
                number: "0x1",
                parent_hash: "0xe10b8035540bf0976aa991dbcc1dfb2237a81706e6848596aca8773a69efb85c",
                nonce: "0x58df949326a72a42",
                timestamp: "0x16d70d9f580",
                transactions_root: "0x249ba6cc038ccb16a18b1da03b994f87a6e32bf128b553a66a5805e9d6f36c50",
                proposals_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
                uncles_count: "0x0",
                uncles_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
                version: "0x0",
                witnesses_root: "0xbfdb7bd77c9be65784a070aef4b21628d930db5bcd6054d8856fd4c28c8aaa2a",
                epoch: "0x3e80001000000",
                dao: "0x2cd631702e870700a715aee035872300a804ad5e9a00000000ec1bc9857a0100" } }
  end

  it "genesis block" do
    expect(api.genesis_block).to be_a(Types::Block)
  end

  it "genesis block hash" do
    expect(api.genesis_block_hash).to be_a(String)
  end

  it "get block" do
    genesis_block_hash = api.get_block_hash(0)
    result = api.get_block(genesis_block_hash)
    expect(result).to be_a(Types::Block)
  end

  it "get block by number" do
    block_number = 0
    result = api.get_block_by_number(block_number)
    expect(result).to be_a(Types::Block)
    expect(result.header.number).to eq block_number
  end

  it "get tip header" do
    result = api.get_tip_header
    expect(result).to be_a(Types::BlockHeader)
    expect(result.number > 0).to be true
  end

  it "get tip block number" do
    result = api.get_tip_block_number
    expect(result > 0).to be true
  end

  it "get cells by lock hash" do
    result = api.get_cells_by_lock_hash(lock_hash, 0, 100)
    expect(result).not_to be nil
  end

  it "get transaction" do
    tx = api.genesis_block.transactions.first
    result = api.get_transaction(tx.hash)
    expect(result).to be_a(Types::TransactionWithStatus)
    expect(result.transaction.hash).to eq tx.hash
  end

  it "get live cell with data" do
    out_point = Types::OutPoint.new(tx_hash: "0x45d086fe064ada93b6c1a6afbfd5e441d08618d326bae7b7bbae328996dfd36a", index: 0)
    result = api.get_live_cell(out_point, true)
    expect(result).not_to be nil
  end

  it "get live cell without data" do
    out_point = Types::OutPoint.new(tx_hash: "0x45d086fe064ada93b6c1a6afbfd5e441d08618d326bae7b7bbae328996dfd36a", index: 0)
    result = api.get_live_cell(out_point)
    expect(result).not_to be nil
  end

  it "send empty transaction" do
    tx = Types::Transaction.new(
      version: 0,
      cell_deps: [],
      inputs: [],
      outputs: []
    )

    expect do
      api.send_transaction(tx)
    end.to raise_error(CKB::RPCError, /:code=>-3/)
  end

  it "get current epoch" do
    result = api.get_current_epoch
    expect(result).not_to be nil
    expect(result).to be_a(Types::Epoch)
  end

  it "get epoch by number" do
    number = 0
    result = api.get_epoch_by_number(number)
    expect(result).to be_a(Types::Epoch)
    expect(result.number).to eq number
  end

  it "local node info" do
    result = api.local_node_info
    expect(result).to be_a(Types::Peer)
  end

  it "get peers" do
    result = api.get_peers
    expect(result).not_to be nil
  end

  it "tx pool info" do
    result = api.tx_pool_info
    expect(result).to be_a(Types::TxPoolInfo)
    expect(result.pending >= 0).to be true
  end

  it "get blockchain info" do
    result = api.get_blockchain_info
    expect(result).to be_a(Types::ChainInfo)
    expect(result.epoch >= 0).to be true
  end

  it "get peers state" do
    result = api.get_peers_state
    expect(result).to be_an(Array)
  end

  it "dry run transaction" do
    tx = Types::Transaction.new(
      version: 0,
      cell_deps: [],
      inputs: [],
      outputs: []
    )

    result = api.dry_run_transaction(tx)
    expect(result).to be_a(Types::DryRunResult)
    expect(result.cycles >= 0).to be true
  end

  context "indexer RPCs" do
    it "index_lock_hash" do
      result = api.index_lock_hash(lock_hash)
      expect(result).not_to be nil
    end

    it "deindex_lock_hash" do
      result = api.deindex_lock_hash(lock_hash)
      expect(result).to be nil
    end

    it "get_lock_hash_index_states" do
      result = api.get_lock_hash_index_states
      expect(result).not_to be nil
    end

    it "get_live_cells_by_lock_hash" do
      result = api.get_live_cells_by_lock_hash(lock_hash, 0, 10)
      expect(result).not_to be nil
    end

    it "get_transactions_by_lock_hash" do
      result = api.get_transactions_by_lock_hash(lock_hash, 0, 10)
      expect(result).not_to be nil
    end
  end

  it "get block header" do
    block_hash = api.get_block_hash(1)
    result = api.get_header(block_hash)
    expect(result).to be_a(Types::BlockHeader)
    expect(result.number > 0).to be true
  end

  it "get block header by number" do
    block_number = 1
    result = api.get_header_by_number(block_number)
    expect(result).to be_a(Types::BlockHeader)
    expect(result.number).to eq block_number
  end

  it "get block reward by block hash" do
    block_hash = api.get_block_hash(1)
    result = api.get_cellbase_output_capacity_details(block_hash)
    expect(result).to be_a(Types::BlockReward)
  end

  it "set ban" do
    params = ["192.168.0.2", "insert", 1_840_546_800_000, true, "test set_ban rpc"]
    result = api.set_ban(*params)
    expect(result).to be nil
  end

  it "get banned addresses" do
    result = api.get_banned_addresses
    expect(result).not_to be nil
    expect(result).to all(be_a(Types::BannedAddress))
  end

  context "miner APIs" do
    it "get_block_template" do
      result = api.get_block_template
      expect(result).not_to be nil
    end

    it "get_block_template with bytes_limit" do
      result = api.get_block_template(bytes_limit: 1000)
      expect(result).to be_a(Types::BlockTemplate)
    end

    it "get_block_template with proposals_limit" do
      result = api.get_block_template(proposals_limit: 1000)
      expect(result).to be_a(Types::BlockTemplate)
    end

    it "get_block_template with max_version" do
      result = api.get_block_template(max_version: 1000)
      expect(result).to be_a(Types::BlockTemplate)
    end

    it "get_block_template with bytes_limit, proposals_limit and max_version" do
      result = api.get_block_template(max_version: 1000)
      expect(result).to be_a(Types::BlockTemplate)
    end

    it "submit_block should return block hash" do
      block = Types::Block.from_h(block_h)
      result = api.submit_block(work_id: "test", raw_block_h: block.to_raw_block_h)
      expect(result).to be_a(String)
    end
  end
end
