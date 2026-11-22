# Gree VRF Protocol Contracts

This directory is the canonical public home for Gree VRF protocol contracts.
It contains separate CAN and UART protocol surfaces; neither surface implies
the framing, electrical properties, direction, delivery, or semantics of the
other.

## CAN

- [Gree VRF CAN bus contract](vrf-canbus.md)
- [What one interface establishes](vrf-canbus.md#what-one-interface-establishes) about system membership and unit roles
- [Machine-readable CAN profile](gree-vrf-can-profile.json)
- [UART-to-CAN command map](gree-vrf-command-map.md)
- [Machine-readable command map](gree-vrf-command-map.json)
- [CAN bridge-record boundary](gree-vrf-can-bridge-record-v1.md)
- [Opaque-cell MCP candidate boundary](gree-vrf-can-opaque-cell-mcp-v1.md)
- [Candidate qualification card](gree-vrf-can-qualification-card-v1.md)
- [Register model](gree-vrf-can-register-model.md): identifier families,
  addressing, coordinates, value types and addressed write frames
- [Machine-readable value types](gree-vrf-can-value-types.json)
- [Parameter dictionary](gree-vrf-can-dictionary.md) and its
  [slices](dictionary/identity.json)
- [Device classes](gree-vrf-can-device-classes.md) and the
  [machine-readable class table](gree-vrf-can-device-classes.json)
- [Presentation converters](gree-vrf-can-presentation-converters.md) and the
  [machine-readable converters and tables](gree-vrf-can-presentation-converters.json)
- [Command contract](gree-vrf-can-command-contract.md)

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

## Publication Basis

The register documents are the register model, the value types, the
parameter dictionary with its slices, the device classes and the
presentation converters.
They state facts (identifiers, types, scaling, units, frames).
Their status is candidate.
They are published at the repository owner's direction (issue #50), and
the public-URL rule in `AGENTS.md` is waived for them only. Native labels
appear as identifiers. English renderings are in our words.

## Safety Boundary

The transport sends the frames a driver submits through its send API and
offers periodic publication. The driver decides what is sent and how often.
The caller configures listen-only for an interface that only receives and
normal mode for one on which a driver sends. The transport does not probe,
configure or bring up an interface on its own. Pure protocol codecs can parse
or construct bounded in-memory values for deterministic conformance work.
Addressed writes use the [command contract](gree-vrf-can-command-contract.md).
