# frozen_string_literal: true

RSpec.describe Legion::Extensions::Velociraptor::Runners::Hunts do
  subject(:client) { Legion::Extensions::Velociraptor::Client.new(api_config: '/tmp/api.yaml', binary: 'velo') }

  before do
    allow(client).to receive(:run_vql).and_return({ rows: [], stderr: '' })
  end

  it 'launches a hunt' do
    client.launch_hunt(artifacts: ['Generic.Client.Info'], description: 'inventory')

    expect(client).to have_received(:run_vql).with(
      vql:    'SELECT hunt(artifacts="Generic.Client.Info", env=dict(), description="inventory") AS hunt FROM scope()',
      env:    {},
      format: :jsonl
    )
  end

  it 'reads hunt results' do
    client.hunt_results(hunt_id: 'H.1234abcd', artifact: 'Generic.Client.Info/BasicInformation')

    expect(client).to have_received(:run_vql).with(
      vql:    'SELECT * FROM source(hunt_id="H.1234abcd", artifact="Generic.Client.Info/BasicInformation")',
      env:    {},
      format: :jsonl
    )
  end

  it 'lists hunts' do
    client.list_hunts

    expect(client).to have_received(:run_vql).with(vql: 'SELECT * FROM hunts()', env: {}, format: :jsonl)
  end
end
