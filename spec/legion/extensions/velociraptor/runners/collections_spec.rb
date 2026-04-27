# frozen_string_literal: true

RSpec.describe Legion::Extensions::Velociraptor::Runners::Collections do
  subject(:client) { Legion::Extensions::Velociraptor::Client.new(api_config: '/tmp/api.yaml', binary: 'velo') }

  before do
    allow(client).to receive(:run_vql).and_return({ rows: [], stderr: '' })
  end

  it 'schedules an artifact collection' do
    client.collect_artifact(client_id: 'C.1234abcd', artifacts: 'Generic.Client.Info', env: { Reason: 'triage' })

    expect(client).to have_received(:run_vql).with(
      vql:    'SELECT collect_client(client_id="C.1234abcd", artifacts="Generic.Client.Info", env=dict(Reason=Reason)) AS collection FROM scope()',
      env:    { Reason: 'triage' },
      format: :jsonl
    )
  end

  it 'builds a wait-and-read collection query' do
    expected_vql = [
      'LET collection <= collect_client(client_id="C.1234abcd", artifacts="Generic.Client.Info", env=dict())',
      "LET _ <= SELECT * FROM watch_monitoring(artifact='System.Flow.Completion') WHERE FlowId = collection.flow_id LIMIT 1",
      'SELECT * FROM source(client_id=collection.request.client_id, flow_id=collection.flow_id, artifact="Generic.Client.Info/BasicInformation")'
    ].join(' ')

    client.collect_artifact_and_wait(
      client_id:       'C.1234abcd',
      artifacts:       ['Generic.Client.Info'],
      result_artifact: 'Generic.Client.Info/BasicInformation'
    )

    expect(client).to have_received(:run_vql).with(
      vql:    expected_vql,
      env:    {},
      format: :jsonl
    )
  end

  it 'reads flow results' do
    client.flow_results(client_id: 'C.1234abcd', flow_id: 'F.5678efgh', artifact: 'Generic.Client.Info/BasicInformation')

    expect(client).to have_received(:run_vql).with(
      vql:    'SELECT * FROM source(client_id="C.1234abcd", flow_id="F.5678efgh", artifact="Generic.Client.Info/BasicInformation")',
      env:    {},
      format: :jsonl
    )
  end

  it 'rejects invalid client ids' do
    expect { client.collect_artifact(client_id: 'bad', artifacts: 'Generic.Client.Info') }
      .to raise_error(ArgumentError, /client_id/)
  end
end
