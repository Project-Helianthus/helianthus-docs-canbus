# CAN library name correspondence

This companion specifies implementation names, not native protocol evidence or
qualification. The [native LINK contract](../protocols/growatt/growatt-low-voltage-bms-can-link-protocol-v1.md)
and [PCS contract](../protocols/growatt/growatt-low-voltage-bms-can-pcs-protocol-v1.md)
retain their status and admission rules. The [inventory](naming-contract.json)
records each library identity, current spelling, target and classification.
Each row's `owning_file` identifies its proof in the public
[canbusreg source tree](https://github.com/Project-Helianthus/helianthus-canbusreg/tree/main).
Provisional and unchanged rows retain their exact spelling; an unresolved name
is not evidence for a new meaning. Historical names are correspondence only,
never runtime fallback keys.

The row classification is **Proven** only as an inventory of inspected source
names; a semantic correspondence beyond the supported map is a **Hypothesis**
until supported, and unresolved quantity, polarity, scope or meaning is
**Unknown**. These grades do not establish qualification.

## Supported map

| Library source | Historical field | Contract field | Proof |
|---|---|---|---|
| `growatt_link_telemetry.go` | `maximum_temperature` | `temperature_maximum` | [LINK telemetry](https://github.com/Project-Helianthus/helianthus-canbusreg/blob/main/growatt_link_telemetry.go) |
| `growatt_link_telemetry.go` | `minimum_temperature` | `temperature_minimum` | [LINK telemetry](https://github.com/Project-Helianthus/helianthus-canbusreg/blob/main/growatt_link_telemetry.go) |
| `growatt_pcs_standard.go` | `maximum_temperature` | `temperature_maximum` | [PCS standard](https://github.com/Project-Helianthus/helianthus-canbusreg/blob/main/growatt_pcs_standard.go) |
| `growatt_pcs_standard.go` | `minimum_temperature` | `temperature_minimum` | [PCS standard](https://github.com/Project-Helianthus/helianthus-canbusreg/blob/main/growatt_pcs_standard.go) |
| `growatt_pcs_parallel_release11.go` | `maximum_temperature` | `temperature_maximum` | [PCS parallel](https://github.com/Project-Helianthus/helianthus-canbusreg/blob/main/growatt_pcs_parallel_release11.go) |
| `growatt_pcs_parallel_release11.go` | `minimum_temperature` | `temperature_minimum` | [PCS parallel](https://github.com/Project-Helianthus/helianthus-canbusreg/blob/main/growatt_pcs_parallel_release11.go) |

The extended PCS decoder retains `maximum_temperature_code` and
`minimum_temperature_code` as raw codes; they are not the two measured fields.
Family and generation gates, raw bytes, value classes, units, scale, polarity,
access and qualification remain unchanged. `maximum_code`, `minimum_code`,
`word_0`, `b4`, `capacity`, `state`, `accumulator`, `charge_limit` and
`discharge_limit` stay provisional where their quantity, polarity, scope or
meaning remains open. Preserve partial last-known-good fields and fail closed
on admission. Gree `GreeVRFMapState.Cells` and `SlotFlags` are opaque map cells;
they do not imply HVAC meanings. CX and O08 Go exports remain unchanged.

## Consumer correspondence

Coordinate the library change with [gateway consumers](https://github.com/Project-Helianthus/helianthus-ebusgateway/tree/main/cmd/gateway),
including LINK and PCS runtimes, project configuration, composition, provider,
CLI and their tests, managed sidecar composition and semantic metrics coverage.
[Home Assistant integration](https://github.com/Project-Helianthus/helianthus-ha-integration)
and [virtual device](https://github.com/Project-Helianthus/helianthus-ebus-vdev)
have no direct matching field in the inspected source; generic passthrough and
schema consumers still require coordination. The [Matter coverage](https://github.com/Project-Helianthus/helianthus-matter-binding/blob/main/docs/target-profile/can-driver-coverage.md)
and [explorer register map](https://github.com/Project-Helianthus/helianthus-vrc-explorer/blob/main/src/helianthus_vrc_explorer/data/myvaillant_register_map.csv)
are correspondence surfaces, not proof that similarly named fields share native
identity. MCP method compatibility and GraphQL value-field parity are retained.
This coordinated pre-1.0 change has no alias, duplicate field, fallback or
migration step.

The gateway correspondence includes these repository-relative paths:

- `cmd/gateway/growatt_link_runtime.go` and `cmd/gateway/growatt_link_runtime_test.go`
- `cmd/gateway/growatt_pcs_runtime.go` and `cmd/gateway/growatt_pcs_runtime_test.go`
- `cmd/gateway/growatt_project_cli.go` and `cmd/gateway/growatt_project_cli_test.go`
- `cmd/gateway/growatt_project_composition_test.go` and `cmd/gateway/growatt_project_conformance_test.go`
- `cmd/gateway/growatt_project_provider.go` and `cmd/gateway/growatt_project_provider_test.go`
- `cmd/gateway/managed_sidecar_composition.go`
- `docs/observability/semantic-prometheus-coverage.md`
- `growatt_project_config.go` and `growatt_project_config_test.go`
