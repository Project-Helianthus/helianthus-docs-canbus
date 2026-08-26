# Gree VRF CAN Opaque-Cell MCP Candidate Boundary V1

This contract describes a read-only candidate view of bounded Gree VRF CAN
state-cell values. It is a native protocol boundary, not a semantic HVAC
model, a device qualification, or an authorization for live CAN I/O.

## Candidate Record

An implementation that exposes a candidate cell through MCP preserves the
native byte value exactly when it is available. The record also carries the
implemented CAN identity and context needed to interpret the observation,
including its protocol/profile version, identifier, cell position, direction,
and observation time where the provider supplies them.

The cell remains opaque: this contract assigns no HVAC meaning, engineering
unit, equipment identity, or command effect to its value. A semantic layer may
selectively promote a later qualified fact, but that projection does not
replace or erase the native candidate record.

## Example

The following is synthetic structural data only. It does not identify an
installation, endpoint, or device.

```json
{
  "profile": "gree-vrf-can-candidate-v1",
  "identifier": "0x00000000",
  "cell_index": 0,
  "value": 0,
  "qualification": "CANDIDATE",
  "observed_at": "1970-01-01T00:00:00Z"
}
```

Implementations must not substitute a digest, a redaction marker, or an
inferred semantic value for an implemented native cell value. A missing value
is reported as unavailable with its native observation/error context; it is
not fabricated from another frame or profile.

## Safety Boundary

This is a read-only API contract. It does not authorize a live controller to
transmit, acknowledge, probe, configure, or otherwise mutate a CAN bus.
Those actions remain subject to the runtime safety contract and action-time
operator confirmation.
