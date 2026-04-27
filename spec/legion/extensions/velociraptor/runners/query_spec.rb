# frozen_string_literal: true

RSpec.describe Legion::Extensions::Velociraptor::Runners::Query do
  subject(:client) { Legion::Extensions::Velociraptor::Client.new(api_config: '/tmp/api.yaml', binary: 'velo') }

  before do
    allow(client).to receive(:run_vql).and_return({ rows: [{ 'ok' => true }], stderr: '' })
  end

  it 'runs raw VQL' do
    result = client.query(vql: 'SELECT * FROM info()')

    expect(result[:rows]).to eq([{ 'ok' => true }])
    expect(client).to have_received(:run_vql).with(vql: 'SELECT * FROM info()', env: {}, format: :jsonl)
  end

  it 'builds server info query' do
    client.server_info

    expect(client).to have_received(:run_vql).with(vql: 'SELECT * FROM info()', env: {}, format: :jsonl)
  end

  it 'passes client search through VQL env' do
    client.search_clients(query: 'host:workstation')

    expect(client).to have_received(:run_vql).with(
      vql:    'SELECT * FROM clients(search=ClientQuery)',
      env:    { ClientQuery: 'host:workstation' },
      format: :jsonl
    )
  end
end
