# lex-velociraptor

Velociraptor DFIR integration for [LegionIO](https://github.com/LegionIO/LegionIO). The extension wraps Velociraptor's supported API-client CLI path so Legion can run server-side VQL, inspect clients, schedule artifact collections, read flow results, and launch hunts without binding Ruby directly to Velociraptor's Go protobufs.

## Installation

```bash
gem install lex-velociraptor
```

## Requirements

- Ruby >= 3.4
- Velociraptor binary available on `PATH`, or set `VELOCIRAPTOR_BIN`
- Velociraptor API client config generated with `velociraptor --config server.config.yaml config api_client`

## Usage

```ruby
require 'legion/extensions/velociraptor'

client = Legion::Extensions::Velociraptor::Client.new(
  api_config: '/secure/path/api.config.yaml',
  binary: '/usr/local/bin/velociraptor'
)

client.query(vql: 'SELECT * FROM info()')
client.search_clients(query: 'host:workstation')
client.collect_artifact(client_id: 'C.1234', artifacts: ['Generic.Client.Info'])
client.flow_results(client_id: 'C.1234', flow_id: 'F.5678', artifact: 'Generic.Client.Info/BasicInformation')
client.launch_hunt(artifacts: ['Generic.Client.Info'], description: 'inventory sweep')
```

## Runners

### Query
`query`, `server_info`, `search_clients`

### Collections
`collect_artifact`, `collect_artifact_and_wait`, `flow_results`, `cancel_flow`

### Hunts
`launch_hunt`, `hunt_results`, `list_hunts`

## Security Notes

Velociraptor's gRPC API can execute powerful server-side VQL. Use a least-privilege API client certificate and store the API config as a secret. Dynamic values are passed as VQL environment variables where practical; runner identifiers such as client IDs, flow IDs, hunt IDs, and artifact names are validated before being interpolated into generated VQL.
