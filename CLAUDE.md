# lex-velociraptor: Velociraptor DFIR Integration for LegionIO

## Purpose

Legion Extension that connects LegionIO to Velociraptor. Provides runners for server-side VQL, client inventory, artifact collections, flow results, and hunts through Velociraptor's supported API-client CLI.

**GitHub**: https://github.com/LegionIO/lex-velociraptor
**License**: MIT
**Version**: 0.1.0

## Architecture

```
Legion::Extensions::Velociraptor
├── Runners/
│   ├── Query        # Raw VQL, server info, client search
│   ├── Collections  # collect_client, wait for flow completion, source results, cancel flow
│   └── Hunts        # hunt launch, hunt result reads, hunt listing
├── Helpers/
│   └── Cli          # Open3 wrapper for velociraptor --api_config ... query --format jsonl
└── Client           # Standalone client class including all runners
```

## Dependencies

| Gem | Purpose |
|-----|---------|
| `legion-*` | Extension runtime helpers and shared Legion services |

## Connection

The client accepts `api_config`, `binary`, and `timeout`. `api_config` can also be provided by `VELOCIRAPTOR_API_CONFIG`, and `binary` defaults to `VELOCIRAPTOR_BIN` or `velociraptor`.

## Testing

```bash
bundle install
bundle exec rspec --format json --out tmp/rspec_results.json --format progress --out tmp/rspec_progress.txt
bundle exec rubocop -A
```

## Maintained By

Matthew Iverson (@Esity)
