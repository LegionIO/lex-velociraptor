# lex-velociraptor

Velociraptor DFIR automation for [LegionIO](https://github.com/LegionIO/LegionIO).

`lex-velociraptor` gives Legion a clean control surface for Velociraptor operations:
run server-side VQL, search enrolled clients, launch artifact collections, read
flow results, cancel flows, and create hunts. It intentionally uses
Velociraptor's supported API-client CLI path instead of binding Ruby directly to
Velociraptor's Go protobufs, so it stays aligned with the interface Velocidex
documents for external automation.

## Why This Exists

Velociraptor is excellent at endpoint collection, live response, and DFIR
investigation. Legion is excellent at coordinating work across tools, agents,
queues, and policy boundaries. This extension connects the two:

- Let Legion agents ask targeted endpoint questions through VQL.
- Trigger Velociraptor artifact collections from Legion workflows.
- Pull completed flow or hunt results back into downstream automation.
- Keep Velociraptor credentials outside prompts and task payloads.
- Avoid unstable GUI/REST internals by using the API-config CLI route.

## Installation

```bash
gem install lex-velociraptor
```

For local development:

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Requirements

- Ruby >= 3.4
- A Velociraptor binary available on `PATH`, or `VELOCIRAPTOR_BIN` set
- A Velociraptor API client config generated from the server configuration
- API roles that match the operations you plan to run

Create the API client config from a Velociraptor server:

```bash
velociraptor \
  --config server.config.yaml \
  config api_client \
  --name legion \
  --role investigator,api \
  api.config.yaml
```

Store `api.config.yaml` like a secret. It contains client key material and can
run whatever the assigned Velociraptor roles allow.

## Configuration

You can pass connection settings directly:

```ruby
require 'legion/extensions/velociraptor'

client = Legion::Extensions::Velociraptor::Client.new(
  api_config: '/secure/path/api.config.yaml',
  binary: '/usr/local/bin/velociraptor'
)
```

Or configure the process environment:

```bash
export VELOCIRAPTOR_BIN=/usr/local/bin/velociraptor
export VELOCIRAPTOR_API_CONFIG=/secure/path/api.config.yaml
```

```ruby
client = Legion::Extensions::Velociraptor::Client.new
```

Optional settings:

| Option | Environment | Default | Purpose |
| --- | --- | --- | --- |
| `api_config` | `VELOCIRAPTOR_API_CONFIG` | `nil` | Path to Velociraptor API client config |
| `binary` | `VELOCIRAPTOR_BIN` | `velociraptor` | Velociraptor executable |
| `timeout` | none | `nil` | Ruby-side command timeout in seconds |

## Quick Start

Run server info:

```ruby
client.server_info
```

Run raw VQL:

```ruby
client.query(vql: 'SELECT * FROM info()')
```

Find clients the same way the Velociraptor GUI search bar does:

```ruby
client.search_clients(query: 'host:workstation')
client.search_clients(query: 'label:servers')
```

Schedule a collection:

```ruby
client.collect_artifact(
  client_id: 'C.1234abcd',
  artifacts: ['Generic.Client.Info']
)
```

Schedule a collection, wait for completion, and read a result source:

```ruby
client.collect_artifact_and_wait(
  client_id: 'C.1234abcd',
  artifacts: ['Generic.Client.Info'],
  result_artifact: 'Generic.Client.Info/BasicInformation'
)
```

Read flow results later:

```ruby
client.flow_results(
  client_id: 'C.1234abcd',
  flow_id: 'F.5678efgh',
  artifact: 'Generic.Client.Info/BasicInformation'
)
```

Launch a hunt:

```ruby
client.launch_hunt(
  artifacts: ['Generic.Client.Info'],
  description: 'inventory sweep'
)
```

Read hunt results:

```ruby
client.hunt_results(
  hunt_id: 'H.1234abcd',
  artifact: 'Generic.Client.Info/BasicInformation'
)
```

## Runner Reference

### Query

#### `query(vql:, env: {}, format: :jsonl, **opts)`

Runs server-side VQL through:

```bash
velociraptor --api_config api.config.yaml query "<VQL>" --format jsonl
```

Returns:

```ruby
{ rows: [...], stderr: "..." }
```

`env` is passed as Velociraptor VQL environment variables using repeated
`--env Name=value` arguments.

#### `server_info(**opts)`

Runs:

```sql
SELECT * FROM info()
```

#### `search_clients(query: nil, **opts)`

Runs:

```sql
SELECT * FROM clients()
SELECT * FROM clients(search=ClientQuery)
```

Use Velociraptor client search syntax such as `host:...` and `label:...`.

### Collections

#### `collect_artifact(client_id:, artifacts:, env: {}, **opts)`

Launches a Velociraptor flow using `collect_client`. Returns the collection
metadata emitted by Velociraptor.

#### `collect_artifact_and_wait(client_id:, artifacts:, result_artifact:, env: {}, **opts)`

Launches a collection, waits for `System.Flow.Completion`, then reads the named
result source with `source(...)`.

This can block until the client returns. Prefer `collect_artifact` plus
`flow_results` for long-running or offline endpoint workflows.

#### `flow_results(client_id:, flow_id:, artifact:, **opts)`

Reads rows from a completed flow using Velociraptor's `source(...)` plugin.

#### `cancel_flow(client_id:, flow_id:, **opts)`

Cancels an outstanding flow.

### Hunts

#### `launch_hunt(artifacts:, description: nil, env: {}, **opts)`

Creates a Velociraptor hunt. Velociraptor hunts created through VQL are active
by default unless the VQL includes pause semantics.

#### `hunt_results(hunt_id:, artifact:, **opts)`

Reads rows from a hunt result source.

#### `list_hunts(**opts)`

Runs:

```sql
SELECT * FROM hunts()
```

## Data Handling

The helper parses `jsonl` output into Ruby hashes with string keys. Blank output
lines are ignored. Command failures raise:

```ruby
Legion::Extensions::Velociraptor::Helpers::Cli::CommandError
```

The error object exposes:

- `exit_status`
- `stderr`
- `stdout`

## Safety Boundaries

Velociraptor VQL is powerful. Treat this extension as a privileged DFIR control
plane, not as a generic shell helper.

- Use least-privilege Velociraptor API roles.
- Store `api.config.yaml` in a secrets-managed path.
- Do not pass API config content through Legion prompts, queue payloads, or logs.
- Prefer VQL environment variables for dynamic values.
- Validate or constrain user-provided artifact names, client IDs, flow IDs, and
  hunt IDs before exposing workflows to untrusted callers.
- Use asynchronous collection patterns for clients that may be offline.

The extension validates common Velociraptor identifiers before interpolating
them into generated VQL and passes dynamic query values through `--env` where
practical.

## Development

Run the full suite:

```bash
bundle exec rspec --format json --out tmp/rspec_results.json --format progress --out tmp/rspec_progress.txt
```

Run style checks:

```bash
bundle exec rubocop -A
```

## Project Links

- LegionIO: https://github.com/LegionIO/LegionIO
- Velociraptor docs: https://docs.velociraptor.app/
- Velociraptor source: https://github.com/Velocidex/velociraptor

## License

MIT
