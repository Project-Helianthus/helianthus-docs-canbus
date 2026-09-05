# Gree VRF Protocol Contracts

This directory is the canonical public home for Gree VRF protocol contracts.
It contains separate CAN and UART protocol surfaces; neither surface implies
the framing, electrical properties, direction, delivery, or semantics of the
other.

## CAN

- [Gree VRF CAN bus contract](vrf-canbus.md)
- [Machine-readable CAN profile](gree-vrf-can-profile.json)
- [UART-to-CAN command map](gree-vrf-command-map.md)
- [Machine-readable command map](gree-vrf-command-map.json)
- [CAN bridge-record boundary](gree-vrf-can-bridge-record-v1.md)
- [Opaque-cell MCP candidate boundary](gree-vrf-can-opaque-cell-mcp-v1.md)
- [Candidate qualification card](gree-vrf-can-qualification-card-v1.md)

The bridge-record boundary is structural only. Its opaque positions, recipient,
direction, and trailer remain unspecified; it is not a complete parser or
serializer contract.

## UART

- [Gree VRF UART contract](vrf-uart.md)
- [Machine-readable UART contract](gree-vrf-uart.json)
- [Profile-qualified property catalog](gree-vrf-property-catalog.md)
- [UART normative vectors](gree-vrf-uart-vectors.json)

Numeric identifiers and raw values are authoritative. Candidate labels are
profile-qualified and noncanonical. Unknown fields remain opaque.

## Safety Boundary

The CAN transport contract is receive-only. Pure protocol codecs can parse or
construct bounded in-memory values for deterministic conformance work, but this
directory does not authorize a live bus operation.
